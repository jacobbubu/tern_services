###
# Helper for accessing redis database
#
###
Redis         = require "redis"
Perf          = require "tern.perf_counter"
Log           = require "tern.logger"
BrokersHelper = require('tern.central_config').BrokersHelper

# Performance Counter Prefix
#   EXAMPLE:
#     "rongmbp.12764.db"
#PerfPrefix = [require("os").hostname(), process.pid, "db"].join "."
PerfPrefix = ""

###
# return true when value in null, undefined or empty string
###
isEmpty = (value) ->
  return true if not value?
    
  type = typeof value
  switch type
    when 'string'
      return value.trim().length is 0
    else
      return false

###
# Add run_script extension
###
Redis.RedisClient.prototype.run_script = (script, args..., next) ->
  
  throw new TypeError "script required." if isEmpty script

  args = args[0] if args.length > 0 and (args[0] instanceof Array)
    
  db = this
  sha1 = db._scripts[script]
  if sha1?
    db.evalsha sha1, args, (err, res) ->
      if err?
        if err is "NOSCRIPT"
          db.script_load script, (err, res) ->
            if err?
              next err, null
            else
              db.evalsha sha1, args, (err, res) ->
                next err, res
        else
          next err, null
      else
        next null, res
  else
    db.script_load script, (err, sha1) ->
      if err?
        next err, null
      else
        db._scripts[script] = sha1
        db.evalsha sha1, args, (err, res) ->
          next err, res

###
# Add EVALSHA extension
###
Redis.RedisClient.prototype.evalsha = (sha1, args..., next) ->
  
  throw new TypeError "sha1 required." if isEmpty sha1

  args = args[0] if args.length > 0 and (args[0] instanceof Array)
  
  db = this
  args.unshift sha1
  db.send_command "EVALSHA", args, (err, res) ->
    if err?      
      err = "NOSCRIPT" if (/error/.test err)
      next err, null
    else
      next null, res

###
# Add SCRIPT LOAD load extension
###
Redis.RedisClient.prototype.script_load = (script, next) ->

  throw new TypeError "script required." if isEmpty script

  db = this
  args = ["LOAD", script]
  db.send_command "SCRIPT", args, (err, res) ->
    next err, res

###
# Add DEL_KEYS extension
#   support redis KEYS pattern
###
Redis.RedisClient.prototype.del_keys = (patterns..., next) ->

  throw new TypeError "patterns required." unless patterns?

  db = this
  script = """
    local len = #ARGV
    local keys
    local deleted = 0
      
    for i = 1, len, 1 do
      keys = redis.call('keys',ARGV[i]);
      for i,v in ipairs(keys) do 
        redis.call('del',v)
        deleted = deleted + 1
      end
    end

    return deleted
  """
  db.run_script script, 0, patterns, (err, res) ->
    next err, res

getDbConfig = (dbName) ->
  configObj = BrokersHelper.getConfig "databases/#{dbName}"
  if configObj?
    configObj.value
  else
    result = 
      host: 'localhost'
      port: 6379
      dbid: 0
      unixsocket: '/tmp/redis.sock'

getConfig = (dbName, key) ->
  result = null

  configObj = BrokersHelper.getConfig "databases/#{dbName}"
  if configObj?
    if key?
      for shardName, v of configObj.value
        tester = new RegExp v.pattern
        if tester.test key is true
          result = {}
          result.shardName = shardName
          result.host = v.host
          result.port = v.port if v.port?
          result.unixsocket = v.unixsocket if v.unixsocket?
          return result
    else
      return configObj.value

  unless result?
    result = 
      shardName: ''
      host: 'localhost'
      port: 6379
      dbid: 0
      unixsocket: '/tmp/redis.sock'  

# A container of redis clients
class Databases
  
  @openedDb: {}

  @getClient: (config) -> 
    throw new TypeError "db config required." unless config?

    if config.unixsocket?
      client = Redis.createClient config.unixsocket
    else
      client = Redis.createClient config.port, config.host

    client._dbid    = config.dbid ? 0
    client._name    = config.fullName
    client._scripts = {}

    if client._dbid isnt 0
      client.select client._dbid, (err, res) ->
        if err?
          message = "#{client._name} - Select to database('#{client._dbid}') failed."
          Log.error message
          throw new Error(message)
        return
  
    # Event listener for "ready". "ready" event will be fired about connection established and redis server responded "info" query
    client.on "ready", (err) ->

      Perf.increment [PerfPrefix, client._name].join "."

      #Log.info "#{client._name} - Connection to redis server created."

      return

    # Error occured on the connection to redis server
    client.on "error", (err) ->
      Log.error "#{client._name} - Error occured: #{err}."
      return

    # Fired when server closed the connection or client quited
    client.on "end", (err) ->

      delete Databases.openedDb[client._name]
      
      Perf.decrement [PerfPrefix, client._name].join "."

      #Log.info "#{client._name} - Connection to redis server lost."
      return

    client

  @add: (dbName, key) -> 
    config = getConfig dbName, key
    if key?
      config.fullName = [dbName, config.shardName].join '/'
    else
      config.fullName = dbName

    unless Databases.openedDb[config.fullName]?    
      Databases.openedDb[config.fullName] = Databases.getClient config
    Databases.openedDb[config.fullName]

  @remove: (dbName) ->
    Databases.openedDb[dbName].end()
    delete Databases.openedDb[dbName]

exports.getDB = (dbName, key) ->
  key = null if typeof key is 'undefined'
  return Databases.add dbName, key
