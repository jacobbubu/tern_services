Log             = require('ternlibs').logger
Err             = require('ternlibs').exceptions
Checker         = require('ternlibs').param_checker
DB              = require('ternlibs').database
Utils           = require('ternlibs').utils
Timers          = require('timers')
WSMessageHelper = require('ternlibs').ws_message_helper

FolderNames = ['memos', 'tags']
DefaultWinSize = 200
MaxWinSize = 500
MinWinSize = 1

MinWaitTime = 100
MaxWaitTime = 1500

ParamRules =
  'win_size':
    'RANGE': 
	    min: MinWinSize
	    max: MaxWinSize
  'name':
    'UNSUPPORTED/i': FolderNames
  'min_ts':
    'STRING_INTEGER_WITH_INF': true
  'max_ts':
    'STRING_INTEGER_WITH_INF': true

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _SubscriptionModel

class _SubscriptionModel
  constructor: () ->
    @db = DB.getDB 'UserDataDB'

  #Changlog Checking
  subsChecking: (connection, subs) => 

    calcWaitTime = () =>
      totalConns = connection._tern.ws_server.connections.length
      Math.min MinWaitTime + totalConns, MaxWaitTime
        
    if Object.keys(subs.folders).length isnt 0
      waitTime = calcWaitTime()
    else
      waitTime = MaxWaitTime
    
    #Clear old timer
    if connection._tern.timeoutId?
      Timers.clearTimeout connection._tern.timeoutId 
      connection._tern.timeoutId = null

    @changeLogChecking connection, subs, (err, res) =>
      Log.error err.toString() if err?

      #console.log res.folders
      #console.log ("#{fName}:#{f.changelog.length}" for fName, f of res.folders), "SubsTimer will run after #{waitTime} ms."

      #Create a new timer
      connection._tern.timeoutId = Timers.setTimeout(@subsChecking, waitTime, connection, subs)
      return

  changeLogChecking: (connection, subs, next) =>

    user_id = connection._tern.user_id
    device_id = connection._tern.device_id

    script = """
      local userId    = ARGV[1]
      local folders   = cjson.decode(ARGV[2])
      local totalSize = ARGV[3]
      local deviceId  = ARGV[4]

      local changelogBase = 'users/'..userId..'/changelog/'
      local changelogKey

      local result = {}
      local fRes, dRes
      local count = 0

      local function array_concat(arr1, arr2)
        for _, v in ipairs(arr2) do
          arr1[#arr1+1] = v
        end
        return arr1
      end

      local devices = redis.call('SMEMBERS', 'users/'..userId..'/devices')

      for name, f in pairs(folders) do
        fRes = {}
        for _, dev in pairs(devices) do
          if dev ~= deviceId then
            changelogKey = changelogBase..name..'/'..dev
            dRes = redis.call('ZRANGEBYSCORE', changelogKey, f.min_ts, f.max_ts, 'LIMIT', 0, f.win_size)
            fRes = array_concat(fRes, dRes)
          end
        end
        if next(fRes) == nil then
          fRes = nil
        end
        result[name] = fRes
      end

      return cjson.encode(result)  
    """

    @db.run_script script
      , 0
      , user_id                       #ARGV[1]
      , JSON.stringify(subs.folders)  #ARGV[2]
      , device_id                     #ARGV[3]
      , (err, res) =>
        return next err if err?

        try        
          finalResult = 
            total_count: 0
            folders: {}

          result = JSON.parse(res)
          for folderName, logs of result

            if Object.keys(logs).length > 0
              logs.sort (log1, log2) ->
                return 0 if log1.ts is log2.ts
                if log1.ts < log2.ts then -1 else 1

              win_size = subs.folders[folderName]?.win_size
              if win_size?
                originalLength = logs.length
                logs.splice Math.min logs.length, win_size
                if logs.length > 0
                  finalResult.folders[folderName] = 
                    changelog: logs
                    has_more : originalLength > logs.length

          if Object.keys(finalResult.folders).length is 0
            return next null, finalResult

          totalCount = subs.win_size
          currentCount = 0
          shouldDelete = false

          for k, f of finalResult.folders
            if shouldDelete
              delete finalResult.folders[k]
            else
              if currentCount + f.changelog.length >= totalCount
                originalLength = f.changelog.length
                f.changelog.splice totalCount - currentCount
                f.has_more = originalLength > f.changelog.length
                shouldDelete = true
                currentCount = totalCount - currentCount
              else
                currentCount = currentCount + f.changelog.length

          finalResult.total_count = currentCount
          
          pushRequest = 
            request:
              method: 'data.subscription.push'
              req_ts: Utils.getTimestamp()
              data  : finalResult

          WSMessageHelper.send connection, JSON.stringify(pushRequest), (err) =>
            return next err if err?

            # delete subs items after sent to client
            for k, f of finalResult.folders
              if subs.folders[k]?
                delete subs.folders[k]

            return next null, finalResult

        catch e 
          return next e                

  subscribe: (request, connection, next) =>

    data = request.data

    error = null
    error = Checker.checkRulesWithError "data", data, { 'OBJECT': true }, error

    unless error?
      if data.win_size?
        error = Checker.collectErrors 'win_size', data, ParamRules, error

      if data.folders?
        for folderName, folder of data.folders
          error = Checker.checkRulesWithError "folders[#{folderName}]", folderName, ParamRules.name, error

          if folder.win_size?
            error = Checker.checkRulesWithError "folders[#{folderName}].win_size", folder.win_size, ParamRules.win_size, error

          error = Checker.checkRulesWithError "folders[#{folderName}].min_ts", folder.min_ts, ParamRules.min_ts, error
          error = Checker.checkRulesWithError "folders[#{folderName}].max_ts", folder.max_ts, ParamRules.max_ts, error

    if error?
      res = {status: -1, error: error }
      return next null, res

    subs = connection._tern.subscritions
    unless subs?
      subs = 
        win_size  : DefaultWinSize
        folders   : {}

    subs.win_size = data.win_size if data.win_size?

    for folderName, folder of data.folders
      subs.folders[folderName] = {} unless subs.folders[folderName]?
      if folder.win_size?
        subs.folders[folderName].win_size = folder.win_size
      else
        subs.folders[folderName].win_size ?= DefaultWinSize

      subs.folders[folderName].min_ts = folder.min_ts
      subs.folders[folderName].max_ts = folder.max_ts

    connection._tern.subscritions = subs

    res = { status: 0 }
    
    Timers.setTimeout @subsChecking, 0, connection, subs

    return next null, res

  unsubscribe: (request, connection, next) =>

    data = request.data

    error = null
    error = Checker.checkRulesWithError "data", data, { 'ARRAY': true }, error

    for folderName in data
      error = Checker.checkRulesWithError "#{folderName}", folderName, ParamRules.name, error
      
    if error?
      res = {status: -1, error: error }
      return next null, res

    subs = connection._tern.subscritions
    if subs?
      for folderName in data
        if subs.folders[folderName]?
          delete subs.folders[folderName]

      connection._tern.subscritions = subs

    res = { status: 0 }
    return next null, res

  get: (connection, next) =>
    res = { status: 0, result: connection._tern.subscritions }
    return next null, res

###
# Module Exports
###
subscriptionModel = coreClass.get()

module.exports.subscribe = (request, connection, next) =>
  subscriptionModel.subscribe request, connection, (err, res) ->
    next err, res if next? 

module.exports.unsubscribe = (request, connection, next) =>
  subscriptionModel.unsubscribe request, connection, (err, res) ->
    next err, res if next? 

module.exports.get = (connection, next) =>
  subscriptionModel.get connection, (err, res) ->
    next err, res if next? 
