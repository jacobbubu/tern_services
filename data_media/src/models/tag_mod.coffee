Log           = require('tern.logger')
Err           = require('tern.exceptions')
Checker       = require('tern.param_checker')
DB            = require('tern.database')
Utils         = require('tern.utils')
Async         = require "async"
Assert        = require "assert"
DBKeys        = require "./dbkeys"

ParamRules = 
  'op':
    'UNSUPPORTED': [1..3]
  'tid':
    'NAME_INTEGER': true
  'parent':
    'NAME_INTEGER': true    
  'created_at': 
    'ISODATE': true
  'updated_at': 
    'ISODATE': true
  'deleted_at': 
    'ISODATE': true    
  'value':
    'REQUIRED': true
  'old_ts':
    'STRING_INTEGER': true
  'key':
    'TAG_KEY': true

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _TagModel

class _TagModel
  constructor: () ->
    @db = DB.getDB 'userDataDB'

  upload: (request, next) =>
    user_id = request._tern.user_id
    device_id = request._tern.device_id
    
    Assert(user_id?, "user_id should not be null!")
    Assert(device_id?, "device_id should not be null!")

    tagKeyBase        = DBKeys.TagsBase user_id
    tagKeyMappingBase = DBKeys.TagKeyMappingBase user_id
    changeLogKey      = DBKeys.TagsChangeLogKey user_id, device_id
    tidMidBaseKey     = DBKeys.TidMidBaseKey user_id
    memoBase          = DBKeys.MemosBase user_id
    memoChangeLogKey  = DBKeys.MemosChangeLogKey user_id, device_id
    devicesKey        = DBKeys.DevicesKey user_id

    processItem = (tag, cb) =>

      errorResponse = (status, error) =>
        res = {}
        res.op      = tag.op if tag.op?
        res.tid     = tag.tid if tag.tid?
        res._order  = tag._order
        
        res.status = status
        res.error = error
        return res

      sameArgsCheck = (error) =>
        error = Checker.collectErrors 'tid', tag, ParamRules, error
        error = Checker.collectErrors 'key', tag, ParamRules, error

        if tag.parent?
          error = Checker.collectErrors 'parent', tag, ParamRules, error

        #error = Checker.collectErrors 'value', tag, ParamRules, error

        return error

      addArgsCheck = () =>
        error = null
        error = Checker.collectErrors 'created_at', tag, ParamRules, error
        
        return sameArgsCheck(error)

      updateArgsCheck = () =>
        error = null
        error = Checker.collectErrors 'tid', tag, ParamRules, error
        error = Checker.collectErrors 'updated_at', tag, ParamRules, error
        error = Checker.collectErrors 'old_ts', tag, ParamRules, error
        
        return sameArgsCheck(error)

      deleteArgsCheck = () =>
        error = null
        error = Checker.collectErrors 'tid', tag, ParamRules, error
        error = Checker.collectErrors 'deleted_at', tag, ParamRules, error
        error = Checker.collectErrors 'old_ts', tag, ParamRules, error

      add = (next) => 

        savingObject =
          ts         : Utils.getTimestamp()
          op         : tag.op
          tid        : tag.tid
          created_at : tag.created_at
          created_by : 'user:' + user_id
          device_id  : device_id
          key        : tag.key
          parent     : tag.parent ? '0000'
          children   : JSON.stringify []
          value      : JSON.stringify tag.value

        #savingObject.value = JSON.stringify tag.value if tag.value?
        
        script = """
          local tagKeyBase        = ARGV[1]..'/'
          local tagKeyMappingBase = ARGV[2]..'/'
          local tagChangeLogKey   = ARGV[3]
          local devicesKey        = ARGV[4]
          local tag_json          = ARGV[5]
          local tag               = cjson.decode(tag_json)

          local tagKey   = tagKeyBase..tag.tid
          local tagExist = redis.call('EXISTS', tagKey)

          local function add(t, ele)    
            for _, value in pairs(t) do
              if value == ele then
                return
              end
            end
            t[#t+1] = ele
          end

          if tagExist == 1 then
            return { -2, redis.call('HGETALL', tagKey) }
          end

          local existingTid = redis.call('GET', tagKeyMappingBase..tag.key)
          if existingTid then
            if existingTid ~= tag.tid then
              return { -6, redis.call('HGETALL', tagKeyBase..existingTid) }
            end
          end
          
          -- Check parent and add tid to parent.children
          if tag.parent ~= '0000' then
            local parentKey = tagKeyBase..tag.parent
            if redis.call('EXISTS', parentKey) == 1 then
              local children = cjson.decode(redis.call('HGET', parentKey, 'children'))
              add(children, tag.tid)
              redis.call('HSET', parentKey, 'children', cjson.encode(children))
            else
              return {-5}
            end
          end

          if existingTid == false then
            redis.call('SET', tagKeyMappingBase..tag.key, tag.tid)
          end
          
          -- Saving tag data
          for k, v in pairs(tag) do
            if k ~= 'op' then
              redis.call('HSET', tagKey, k, v)
            end
          end

          -- Add Device, only for 'add' op
          redis.call('SADD', devicesKey, tag.device_id)
          -- Loggin changes
          redis.call('ZADD', tagChangeLogKey, tag.ts, tag_json)

          return {0}
        """

        @db.run_script script
          , 0                             # 0 keys
          , tagKeyBase                    # ARGV[1]
          , tagKeyMappingBase             # ARGV[2]
          , changeLogKey                  # ARGV[3]
          , devicesKey                    # ARGV[4]
          , JSON.stringify(savingObject)  # ARGV[5]
          , (err, res) ->
            return next err if err?

            switch res[0]
              when 0
                result =
                  ts: savingObject.ts
                  tid: tag.tid
              when -2, -6
                result = Utils.redisArrayToObject res[1]
              when -5
                tid: tag.tid
            
            delete result.children
             
            result.status = res[0]
            result._order = tag._order
            result.op = tag.op
            result.value = JSON.parse result.value if result.value?
            
            return next null, result

      upd = (next) => 
        old_ts = tag.old_ts
        
        savingObject =
          ts         : Utils.getTimestamp()
          op         : tag.op
          tid        : tag.tid
          updated_at : tag.updated_at
          updated_by : 'user:' + user_id
          device_id  : device_id
          key        : tag.key
          value      : JSON.stringify tag.value
          parent     : tag.parent ? '0000'
      
        script = """
          local tagKeyBase        = ARGV[1]..'/'
          local tagKeyMappingBase = ARGV[2]..'/'
          local tagChangeLogKey   = ARGV[3]

          local old_ts     = ARGV[4]
          local tag_json   = ARGV[5]
          local devicesKey = ARGV[6]

          local tag       = cjson.decode(tag_json)
          local tagKey    = tagKeyBase..tag.tid

          local function add(t, ele)    
            for _, value in pairs(t) do
              if value == ele then
                return
              end
            end
            t[#t+1] = ele
          end

          local function remove(t, ele)    
            for i, value in pairs(t) do
              if value == ele then
                table.remove(t, i)
              end
            end
          end

          local curr_ts = redis.call('HGET', tagKey, 'ts')
          if curr_ts then
            -- Has newer version?
            if curr_ts > old_ts then
              return { 1, redis.call('HGETALL', tagKey) }
            end
          else
            return {-3}
          end

          -- new key exists and mapps to different tid?
          local newTagKeyMappingKey = tagKeyMappingBase..tag.key
          local tid_of_new_key = redis.call('GET', newTagKeyMappingKey)

          if tid_of_new_key then
            if tid_of_new_key ~= tag.tid then
              return {-6, tid_of_new_key}
            end
          end

          -- Rename key name of old tagkey to new one
          local oldTagKey = redis.call('HGET', tagKey, 'key')
          local oldTagKeyMappingKey = tagKeyMappingBase..oldTagKey

          if oldTagKeyMappingKey ~= newTagKeyMappingKey then
            redis.call('RENAME', oldTagKeyMappingKey, newTagKeyMappingKey)
          end

          -- Check parent of old tag and add tid to parent.children
          local oldParent = redis.call('HGET', tagKey, 'parent')
          local parentKey
          local children

          if oldParent ~= tag.parent then
            -- Check parent of new tag and add tid to parent.children
            if tag.parent ~= '0000' then
              parentKey = tagKeyBase..tag.parent
              if redis.call('EXISTS', parentKey) == 1 then
                children = cjson.decode(redis.call('HGET', parentKey, 'children'))
                add(children, tag.tid)
                redis.call('HSET', parentKey, 'children', cjson.encode(children))
              else
                return {-5}
              end
            end            

            if oldParent ~= '0000' then
              parentKey = tagKeyBase..oldParent
              if redis.call('EXISTS', parentKey) == 1 then
                children = cjson.decode(redis.call('HGET', parentKey, 'children'))
                remove(children, tag.tid)
                redis.call('HSET', parentKey, 'children', cjson.encode(children))
              end
            end
          end

          -- Saving tag data
          for k, v in pairs(tag) do
            if k ~= 'op' then
              redis.call('HSET', tagKey, k, v)
            end
          end

          -- Add Device, only for 'add' op
          redis.call('SADD', devicesKey, tag.device_id)
          -- Loggin changes
          redis.call('ZADD', tagChangeLogKey, tag.ts, tag_json)

          return {0}
        """

        @db.run_script script
          , 0                             # 0 keys
          , tagKeyBase                    # ARGV[1]
          , tagKeyMappingBase             # ARGV[2]
          , changeLogKey                  # ARGV[3]
          , old_ts                        # ARGV[4]
          , JSON.stringify(savingObject)  # ARGV[5]
          , devicesKey                    # ARGV[6]
          , (err, res) =>
            return next err if err?

            switch res[0]
              when  0 
                result = 
                  tid: savingObject.tid
                  ts:  savingObject.ts
              when  1 
                result = Utils.redisArrayToObject res[1]
              when -3, -5 
                result =
                  tid: savingObject.tid
              when -6 
                result =
                  tid_of_new_key: res[1]

            delete result.children
            result._order = tag._order
            result.op = tag.op
            result.status = res[0]

            return next null, result

      # Delete a tag, we should
      #   check ts first
      #   delete tagkey_to_tid key
      #   delete tag
      #   delete tid from all memos that have this tag
      #   insert tagChangeLog
      #   insert memoChangeLog (huge)
      del = (next) => 

        new_ts = Utils.getTimestamp()
        #delete tag, tagKeyMapping, tid_mid, then add changelog
        deleteObject =
          ts        : new_ts
          op        : 3
          tid       : tag.tid
          deleted_at : tag.deleted_at
          deleted_by : 'user:' + user_id
          device_id  : device_id

        # Use it for memoChangeLog update lead by tag removing
        memoChangeObject =
          op         : 2        #update          
          updated_at : tag.deleted_at
          updated_by : user_id
          device_id  : device_id

        script = """
          local tagKeyBase        = ARGV[1]..'/'
          local tagKeyMappingBase = ARGV[2]..'/'
          local tidMidBaseKey     = ARGV[3]..'/'
          local memoBase          = ARGV[4]..'/'
          local tagChangeLogKey   = ARGV[5]
          local memoChangeLogKey  = ARGV[6]
          local old_ts            = ARGV[7]
          local memoChangeObject  = cjson.decode(ARGV[8])
          local tagObject         = cjson.decode(ARGV[9])
          local devicesKey        = ARGV[10]
                    
          local ts                = tonumber(tagObject.ts)

          local tagKey            = tagKeyBase..tagObject.tid

          local curr_ts = redis.call('HGET', tagKey, 'ts')
          if curr_ts then
            -- Has newer version?
            if curr_ts > old_ts then
              return { 1, redis.call('HGETALL', tagKey) }
            end
          else
            return {-3}
          end

          -- find out all children then put them into tagsNeedDeleted
          local tagsNeedDeleted = {tagObject.tid}

          local function array_concat(arr)
            for _, v in ipairs(arr) do
              tagsNeedDeleted[#tagsNeedDeleted+1] = v
            end
            return
          end

          local function getChildren(tagKey)
            local json = redis.call('HGET', tagKey, 'children')
            if json ~= false then
              local arr = cjson.decode(json)
              array_concat(arr)
              for k, v in pairs(arr) do
                getChildren(tagKeyBase..v)
              end
            else
              return
            end
          end

          getChildren(tagKey)

          local function remove(t, ele)    
            for i, value in pairs(t) do
              if value == ele then
                table.remove(t, i)
              end
            end
          end

          local function deleteOneTag(tid)
            tagKey = tagKeyBase..tid
            tagObject.tid = tid
            tagObject.ts = string.format('%u', ts)
            ts = ts + 1 

            --Delete tagkey_to_tid
            local oldTagKey = redis.call('HGET', tagKey, 'key')
            if oldTagKey ~= false then
              local oldTagKeyMappingKey = tagKeyMappingBase..oldTagKey
              redis.call('DEL', oldTagKeyMappingKey)
            end

            -- Get parent of deleted tag and remove tid from parent.children
            local oldParent = redis.call('HGET', tagKey, 'parent')
            local parentKey
            local children

            if oldParent ~= '0000' then
              parentKey = tagKeyBase..oldParent
              if redis.call('EXISTS', parentKey) == 1 then
                children = cjson.decode(redis.call('HGET', parentKey, 'children'))
                remove(children, tid)
                redis.call('HSET', parentKey, 'children', cjson.encode(children))
              end
            end

            -- Delete tag hash
            redis.call('DEL', tagKey)

            -- Delete tid_mid
            local tidMidKey = tidMidBaseKey..tid
            local allMid = redis.call('ZRANGE', tidMidKey, 0, -1)
            local tagsJSON
            local tags
            local newTagsJson

            if #allMid > 0 then 
              for _, mid in pairs(allMid) do
                tagsJSON = redis.call('HGET', memoBase..mid, 'tags')
                if tagsJSON then
                  tags = cjson.decode(tagsJSON)
                  for i, tag in pairs(tags) do
                    if tag.tid == tid then
                      table.remove(tags, i)
                    end
                  end
                  -- update memo.tags
                  if #tags == 0 then
                    newTagsJson = '[]'
                  else
                    newTagsJson = cjson.encode(tags)
                  end
                  redis.call('HSET', memoBase..mid, 'tags', newTagsJson)
                  -- add memo changelog
                  memoChangeObject.ts = tagObject.ts
                  memoChangeObject.mid = mid
                  memoChangeObject.tags = newTagsJson
                  redis.call('ZADD', memoChangeLogKey, memoChangeObject.ts, cjson.encode(memoChangeObject))
                end
              end
              redis.call('DEL', tidMidKey)
              --delete all_tags member here (zrem [user_id]/all_tags tid)
            end

            -- Add Device, only for 'add' op
            redis.call('SADD', devicesKey, tagObject.device_id)
            -- Loggin changes
            redis.call('ZADD', tagChangeLogKey, tagObject.ts, cjson.encode(tagObject))
          end

          for _, tid in ipairs(tagsNeedDeleted) do
            deleteOneTag(tid)
          end

          return {0}
        """

        @db.run_script script
          , 0                                 # 0 keys
          , tagKeyBase                        # ARGV[1]
          , tagKeyMappingBase                 # ARGV[2]
          , tidMidBaseKey                     # ARGV[3]
          , memoBase                          # ARGV[4]
          , changeLogKey                      # ARGV[5]
          , memoChangeLogKey                  # ARGV[6]
          , tag.old_ts                        # ARGV[7]
          , JSON.stringify(memoChangeObject)  # ARGV[8]
          , JSON.stringify(deleteObject)      # ARGV[9]
          , devicesKey                        # ARGV[10]
          , (err, res) =>
            return next err if err?

            switch res[0]
              when  0 
                result = 
                  tid: tag.tid
                  ts: new_ts
              when  1 
                result = Utils.redisArrayToObject res[1]
              when -3 
                result =
                  tid: tag.tid

            result._order = tag._order
            result.op = tag.op
            result.status = res[0]
            
            return next null, result

      # op check
      try
        error = Checker.collectErrors 'op', tag, ParamRules, null    
      catch e
        return cb(e)
            
      if error?
        finalResponse.push errorResponse(-1, error) 
        return cb()

      try
        switch tag.op
          when 1  #Add
            error = addArgsCheck()
          when 2  #Update
            error = updateArgsCheck()
          when 3  #delete
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

      #tagKey = DBKeys.TagsKey user_id, tag.tid

      #Save to DB
      switch tag.op
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

###
# Modulereturn Exports
###
tagModel = coreClass.get()

module.exports.upload = (request, next) =>
  tagModel.upload request, (err, res) ->
    next err, res if next?
