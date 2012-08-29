Log           = require('tern.logger')
Err           = require('tern.exceptions')
Checker       = require('tern.param_checker')
DB            = require('tern.database')
Utils         = require('tern.utils')
Async         = require "async"
Assert        = require "assert"
DBKeys        = require "./dbkeys"
MediaAgent    = require "../agents/media_agent"


OP = 
  'add'    : 1
  'update' : 2
  'delete' : 3

ValidContentTypes = ['image/png', 'image/jpeg', 'image/gif', 'audio/mpeg', 'video/h264', 'video/mp4' ]
MaxMediaSize      = 100 * 1024 * 1024  # 100M
MaxTextSize       = 2 * 1024
MaxTS             = 999999999999999

ParamRules = 
  'op':
    'UNSUPPORTED': [1..3]
  'created_at': 
    'ISODATE': true
  'updated_at': 
    'ISODATE': true
  'deleted_at': 
    'ISODATE': true    
  'media_meta.content_type': 
    'UNSUPPORTED/i': ValidContentTypes
  'media_meta.content_length':
    'INTEGER': true
    'RANGE':
      min: 1
      max: MaxMediaSize
  'media_meta.md5':
    'LENGTH':
      min: 32
      max: 32
  'text':
    'LENGTH':
      min: 0
      max: MaxTextSize
  'geo.lat':
    'RANGE':
      min: -90
      max: 90
  'geo.lng':
    'RANGE':
      min: -180
      max: 180
  'mid':
    'NAME_INTEGER': true
  'old_ts':
    'STRING_INTEGER': true
  'tags':
    'ARRAY': true

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _MemoModel

class _MemoModel
  constructor: () ->
    @db = DB.getDB 'userDataDB'


  upload: (request, next) =>

    user_id = request._tern.user_id
    device_id = request._tern.device_id
    
    Assert(user_id?, "user_id should not be null!")
    Assert(device_id?, "device_id should not be null!")

    changeLogKey  = DBKeys.MemosChangeLogKey(user_id, device_id)    
    tagMidBaseKey = DBKeys.TidMidBaseKey(user_id)
    devicesKey    = DBKeys.DevicesKey(user_id)

    processItem = (memo, cb) =>

      errorResponse = (status, error) =>
        res = {}
        res.op      = memo.op if memo.op?
        res.mid     = memo.mid if memo.mid?
        res._order  = memo._order
        
        res.status = status
        res.error = error
        return res

      sameArgsCheck = (error) =>
        
        error = Checker.collectErrors 'mid', memo, ParamRules, error

        if memo.media_meta?
          if memo.media_meta.content_type?
            error = Checker.collectErrors 'media_meta.content_type', memo, ParamRules, error
          if memo.media_meta.content_length?
            error = Checker.collectErrors 'media_meta.content_length', memo, ParamRules, error
          if memo.media_meta.md5?
            error = Checker.collectErrors 'media_meta.md5', memo, ParamRules, error

        if memo.text?
          error = Checker.collectErrors 'text', memo, ParamRules, error

        if memo.geo?
          error = Checker.collectErrors 'geo.lat', memo, ParamRules, error
          error = Checker.collectErrors 'geo.lng', memo, ParamRules, error

        if memo.tags?
          if Utils.type(memo.tags) isnt 'array'
            error = Checker.collectErrors 'tags', memo, ParamRules, error
          else
            for tag, index in memo.tags
              error = Checker.checkRulesWithError "tags[#{index}].tid", tag.tid, {'NAME_INTEGER': true }, error

        return error

      addArgsCheck = () =>
        error = null
        error = Checker.collectErrors 'created_at', memo, ParamRules, error

        if not memo.media_meta? and not memo.text?
          error = {} unless error?
          error.media_meta = ["REQUIRED_EITHER:media_meta:text"]

        return sameArgsCheck(error)

      updateArgsCheck = () =>
        error = null
        error = Checker.collectErrors 'updated_at', memo, ParamRules, error
        error = Checker.collectErrors 'old_ts', memo, ParamRules, error
        
        return sameArgsCheck(error)

      deleteArgsCheck = () =>
        error = null
        error = Checker.collectErrors 'deleted_at', memo, ParamRules, error
        error = Checker.collectErrors 'old_ts', memo, ParamRules, error

        return sameArgsCheck(error)

      # Generate TagIdx Array, then merge it
      tagIdxArray = (tagsObject) =>      
        tagIdxs = []
        for tagId, v of tagsObject
          tagKey = v.key
          tagIdxs.merge Utils.keyToTagIdx v.key

        tagIdxs = tagIdxs.unique()

      deleteMedia = (media_zone, media_id) ->
        process.nextTick ->
          MediaAgent.deleteMedia media_zone, media_id, (err) ->
            if err?
              Log.error "Error deleteMedia: #{err.toString()}\r\nData Zone: #{media_zone}, media_id: #{media_id}"

      add = (next) =>
        
        savingObject =
          ts         : Utils.getTimestamp()
          op         : memo.op
          mid        : memo.mid          
          created_at : memo.created_at
          created_by : user_id
          device_id  : device_id

        savingObject.text       = memo.text if memo.text?
        savingObject.media_meta = JSON.stringify memo.media_meta if memo.media_meta?
        savingObject.geo        = JSON.stringify memo.geo if memo.geo?
        savingObject.tags       = JSON.stringify memo.tags if memo.tags?

        script = """
          local memosKey = KEYS[1]
          local memosChangeLogKey = KEYS[2]
          local devicesKey = KEYS[3]
          local tagMidBaseKey = ARGV[1]..'/'
          local score = ARGV[2]
          local memo_json = ARGV[3]
          local affectedCount
          
          local memoExist = redis.call('EXISTS', memosKey)

          if memoExist == 1 then
            return { -2, redis.call('HGETALL', memosKey) }
          end

          local memo = cjson.decode(memo_json)

          -- Saving memo data
          for k, v in pairs(memo) do
            if k ~= 'op' then
              redis.call('HSET', memosKey, k, v)
            end
          end

          -- tid_mid mapping
          if memo.tags then
            local tags = cjson.decode(memo.tags)
            for _, tag in pairs(tags) do
              affectedCount = redis.call('ZADD', tagMidBaseKey..tag.tid, score, memo.mid)
            end
          end

          -- Add Device, only for 'add' op
          redis.call('SADD', devicesKey, memo.device_id)
          -- Loggin changes
          redis.call('ZADD', memosChangeLogKey, memo.ts, memo_json)

          return {0}
        """

        @db.run_script script
          , 3                             # 2 keys
          , memosKey                      # KEYS[1]
          , changeLogKey                  # KEYS[2]
          , devicesKey                    # KEYS[3]
          , tagMidBaseKey                 # ARGV[1]
          , (+new Date)                   # ARGV[2]
          , JSON.stringify(savingObject)  # ARGV[3]
          , (err, res) =>
            return next err if err?
                                  
            if res[0] is 1
              # mid exists, return old memo
              result = Utils.redisArrayToObject res[1]
              result.media_meta = JSON.parse(result.media_meta) if result.media_meta?
              result.geo  = JSON.parse(result.geo) if result.geo?
              result.tags = JSON.parse(result.tags) if result.tags?              
            else
              result = 
                ts: savingObject.ts

            result.status = res[0]
            result._order = memo._order
            result.mid = memo.mid
            result.op = memo.op
                        
            return next null, result

      upd = (next) =>
        old_ts = memo.old_ts

        savingObject =
          ts         : Utils.getTimestamp()
          op         : memo.op
          mid        : memo.mid
          updated_at : memo.updated_at
          updated_by : user_id
          device_id  : device_id

        savingObject.text       = memo.text if memo.text?
        savingObject.media_meta = JSON.stringify memo.media_meta if memo.media_meta?
        savingObject.geo        = JSON.stringify memo.geo if memo.geo?
        savingObject.tags       = JSON.stringify memo.tags if memo.tags?

        script = """
          local memosKey          = KEYS[1]
          local memosChangeLogKey = KEYS[2]

          local old_ts        = ARGV[1]
          local tagMidBaseKey = ARGV[2]..'/'
          local score         = ARGV[3]

          local memo_json     = ARGV[4]
          local memo          = cjson.decode(memo_json)
          local mid           = memo['mid']
          local affectedCount

          local function contains(table, element)
            for _, value in pairs(table) do
              if value == element then
                return true
              end
            end
            return false
          end
          
          local curr_ts = redis.call('HGET', memosKey, 'ts')
          if curr_ts then
            -- Has newer version?
            if curr_ts > old_ts then
              return { 1, redis.call('HGETALL', memosKey) }
            end
          else
            return {-3}
          end

          local oldMediaMeta = redis.call('HGET', memosKey, 'media_meta')

          local oldTags = redis.call('HGET', memosKey, 'tags')
          local oldTagsArr = {}
          if oldTags then
            oldTags = cjson.decode(oldTags)
            for _, tag in pairs(oldTags) do
              oldTagsArr[#oldTagsArr+1] = tag.tid
            end
          end
          local newTags = memo.tags
          local newTagsArr = {}
          if newTags then
            newTags = cjson.decode(newTags)
            for _, tag in pairs(newTags) do
              newTagsArr[#newTagsArr+1] = tag.tid
            end
          end

          -- Saving memo data
          for k, v in pairs(memo) do
            if k ~= 'op' then          
              if k == 'media_meta' then
                redis.call('HDEL', memosKey, 'text')
              end
              if k == 'text' then
                redis.call('HDEL', memosKey, 'media_meta')
              end              
              redis.call('HSET', memosKey, k, v)
            end
          end

          -- tid_mid we need to remove
          for _, tid in pairs(oldTagsArr) do
            if contains(newTagsArr, tid) == false then
              affectedCount = redis.call('ZREM', tagMidBaseKey..tid, mid)
            end
          end

          -- tid_mid we need to add
          for _, tid in pairs(newTagsArr) do
            if contains(oldTagsArr, tid) == false then
              affectedCount = redis.call('ZADD', tagMidBaseKey..tid, score, mid)
            end
          end

          -- Loggin changes
          redis.call('ZADD', memosChangeLogKey, memo.ts, memo_json)

          return {0, oldMediaMeta}
        """

        @db.run_script script
          , 2                             # 2 keys
          , memosKey                      # KEYS[1]
          , changeLogKey                  # KEYS[2] 
          , old_ts                        # ARGV[1]
          , tagMidBaseKey                 # ARGV[2]
          , (+new Date)                   # ARGV[3]
          , JSON.stringify(savingObject)  # ARGV[4]
          , (err, res) =>
            return next err if err?
                      
            switch res[0]
              when  0 
                result = 
                  mid: savingObject.mid
                  ts: savingObject.ts

                oldMediaMeta = res[1]
                if oldMediaMeta?.media_zone?
                  deleteMedia oldMediaMeta?.media_zone, memo.mid
                    
              when  1 
                result = Utils.redisArrayToObject res[1]
              when -3 
                result =
                  mid: savingObject.mid

            result._order = memo._order
            result.op = memo.op
            result.status = res[0]

            if result.status is 1
              result.media_meta = JSON.parse(result.media_meta) if result.media_meta?
              result.geo = JSON.parse(result.geo) if result.geo?
              result.tags = JSON.parse(result.tags) if result.tags?
            
            return next null, result
            
      del = (next) =>
        new_ts = Utils.getTimestamp()

        script = """
          local memosKey          = KEYS[1]
          local memosChangeLogKey = KEYS[2]

          local user_id       = ARGV[1]
          local device_id     = ARGV[2]
          local mid           = ARGV[3]
          local old_ts        = ARGV[4]
          local new_ts        = ARGV[5]
          local deleted_at    = ARGV[6]
          local tagMidBaseKey = ARGV[7]..'/'
          local affectedCount

          local curr_ts = redis.call('HGET', memosKey, 'ts')
          if curr_ts then
            -- Has newer version?
            if curr_ts > old_ts then
              return { 1, redis.call('HGETALL', memosKey) }
            end
          else
            return {-3}
          end

          local oldTags = redis.call('HGET', memosKey, 'tags')
          if oldTags then
            oldTags = cjson.decode(oldTags)
          else
            oldTags = {}
          end

          local mediaMeta = redis.call('HGET', memosKey, 'media_meta')

          redis.call('DEL', memosKey)

          for _, tag in pairs(oldTags) do
            affectedCount = redis.call('ZREM', tagMidBaseKey..tag.tid, mid)
          end          

          -- Loggin changes
          local logContent = { op = 3, mid = mid, ts = new_ts, device_id = device_id, deleted_by = user_id, deleted_at = deleted_at }
          redis.call('ZADD', memosChangeLogKey, new_ts, cjson.encode(logContent))

          return {0, mediaMeta}
        """

        @db.run_script script
          , 2                             # 2 keys
          , memosKey                      # KEYS[1]
          , changeLogKey                  # KEYS[2]  
          , user_id                       # ARGV[1]
          , device_id                     # ARGV[2]
          , memo.mid                      # ARGV[3]
          , memo.old_ts                   # ARGV[4]
          , new_ts                        # ARGV[5]
          , memo.deleted_at               # ARGV[6]
          , tagMidBaseKey                 # ARGV[7]
          , (err, res) =>
            return next err if err?
                      
            switch res[0]
              when  0 
                result = 
                  mid: memo.mid
                  ts: new_ts
                
                media_meta = JSON.parse res[1]
                if media_meta?.media_zone?
                  deleteMedia media_meta.media_zone, memo.mid

              when  1 
                result = Utils.redisArrayToObject res[1]
              when -3 
                result =
                  mid: memo.mid

            result._order = memo._order
            result.op = memo.op
            result.status = res[0]

            if result.status is 1
              result.media_meta = JSON.parse(result.media_meta) if result.media_meta?
              result.geo = JSON.parse(result.geo) if result.geo?
              result.tags = JSON.parse(result.tags) if result.tags?
            
            return next null, result
          
      # op check
      try
        error = Checker.collectErrors 'op', memo, ParamRules, null    
      catch e
        return cb(e)
            
      if error?
        finalResponse.push errorResponse(-1, error) 
        return cb()

      try
        switch memo.op
          when 1  #Add
            error = addArgsCheck()
          when 2  #Update
            error = updateArgsCheck()
          when 3  #Delete
            error = deleteArgsCheck()
      catch e
        return cb(e)
      
      if error?
        finalResponse.push errorResponse(-1, error) 
        return cb()

      savingCallback = (err, res) =>
        return cb(err) if err? #Unexpected error, return now.

        finalResponse.push res
        return cb()

      memosKey = DBKeys.MemosKey user_id, memo.mid

      #Save to DB
      switch memo.op
        when 1 then add savingCallback
        when 2 then upd savingCallback
        when 3 then del savingCallback

    # Upload main block
    data = request.data
    error = Checker.checkRulesWithError "data", data, { 'ARRAY': true }, error

    if error?
      res = {status: -1, error: error }
      return next null, res

    finalResponse = []

    for value, index in data
      data[index]._order = index

    Async.forEach data, processItem, (err) =>
      return next err if err?

      finalResponse.sort (m1, m2) ->
        return m1._order - m2._order

      for res in finalResponse
        delete res._order
      
      return next null, finalResponse

  mediaUriWriteback: (changedMemo, next) ->    
    mid        = changedMemo.mid
    user_id    = changedMemo.user_id    
    device_id  = changedMemo.device_id
    updated_at = changedMemo.updated_at
    media_meta = changedMemo.media_meta
    
    Assert(mid?, "mid should not be null!")
    Assert(user_id?, "user_id should not be null!")
    Assert(device_id?, "device_id should not be null!")
    Assert(media_meta?, "media_meta should not be null!")

    request =
      _tern: 
        user_id: user_id
        device_id: device_id
      data: [ {
        op: 2
        mid: mid
        old_ts: Utils.maxTimestamp
        updated_at: updated_at
        media_meta: changedMemo.media_meta
      } ]

    @upload request, (err, res) ->
      next err, res

###
###

###
# Module return Exports
###
memoModel = coreClass.get()

module.exports.upload = (request, next) =>
  memoModel.upload request, (err, res) ->
    next err, res if next? 

module.exports.mediaUriWriteback = (changedMemo, next) =>
  memoModel.mediaUriWriteback changedMemo, (err, res) ->
    next err, res if next? 