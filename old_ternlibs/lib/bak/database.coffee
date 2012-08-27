###
# Helper for accessing redis database
#
###
Redis        = require "redis"
Perf         = require "./perf_counter"
Log          = require "./logger"
Config       = require "./config"
Checker      = require "./param_checker"
Err          = require "./exceptions"
DefaultPorts = require "./default_ports"

# Performance Counter Prefix
#   EXAMPLE:
#     "rongmbp.12764.db"
#PerfPrefix = [require("os").hostname(), process.pid, "db"].join "."
PerfPrefix = ""

###
# Add run_script extension
###
Redis.RedisClient.prototype.run_script = (script, args..., next) ->
  
  throw Err.ArgumentNullException "script required." if Checker.isEmpty script

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
  
  throw Err.ArgumentNullException "sha1 required." if Checker.isEmpty sha1

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

  throw Err.ArgumentNullException "script required." if Checker.isEmpty script

  db = this
  args = ["LOAD", script]
  db.send_command "SCRIPT", args, (err, res) ->
    next err, res

###
# Add DEL_KEYS extension
#   support redis KEYS pattern
###
Redis.RedisClient.prototype.del_keys = (pattern, next) ->

  throw Err.ArgumentNullException "pattern required." if Checker.isEmpty pattern

  db = this
  script = """
    local keys = redis.call('keys',ARGV[1]);
    for i,v in ipairs(keys) do 
      redis.call('del',v) 
    end;
    return #keys
  """
  db.run_script script, 0, pattern, (err, res) ->
    next err, res

# A container of redis clients
class Databases
  
  @openedDb: {}

  @getClient: (dbName) -> 
    throw Err.ArgumentNullException "dbName required." if Checker.isEmpty dbName

    host        = Config[dbName].host       ? "localhost"
    port        = Config[dbName].port       ? DefaultPorts.Redis
    dbid        = Config[dbName].dbid       ? 0
    unixsocket  = Config[dbName].unixsocket ? DefaultPorts.RedisUnix

    if unixsocket?
      client = Redis.createClient unixsocket
    else
      client = Redis.createClient port, host

    client._dbid    = dbid
    client._name    = dbName
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

    return client

  @add: (dbName) -> 
    Databases.openedDb[dbName] = Databases.openedDb[dbName] ? Databases.getClient(dbName)
    return Databases.openedDb[dbName]

  @remove: (dbName) ->
    Databases.openedDb[dbName].end()
    delete Databases.openedDb[dbName]

exports.getDB = (dbName) -> 
  return Databases.add dbName


