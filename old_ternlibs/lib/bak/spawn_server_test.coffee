Log       = require './test_log'
Err       = require('tern.exceptions')
Spawn     = (require 'child_process').spawn

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _SpawnServer

class _SpawnServer
  constructor: () ->
    @spawnServer = null

  waitForOutput: (pattern, next) =>    
    return next() unless @spawnServer?

    stdoutCallback = (data) =>
      message = data.toString()
      if pattern.test message
        @spawnServer.stdout.removeListener 'data', stdoutCallback
        @spawnServer.stderr.removeListener 'data', stderrCallback
        next()

    stderrCallback = (data) =>
      message = data.toString()
      if pattern.test message
        @spawnServer.stdout.removeListener 'data', stdoutCallback
        @spawnServer.stderr.removeListener 'data', stderrCallback
        next()

    @spawnServer.stdout.on 'data', stdoutCallback
    @spawnServer.stderr.on 'data', stderrCallback

  stdoutCallback: (data) =>
    message = data.toString()
    Log.serverLog message

  stderrCallback: (data) =>
    message = data.toString()
    Log.serverError message
    
  startOutputMon: () =>
    @spawnServer.stdout.on 'data', @stdoutCallback
    @spawnServer.stderr.on 'data', @stderrCallback

  stopOutputMon: () =>
    @spawnServer.stdout.removeListener 'data', @stdoutCallback
    @spawnServer.stderr.removeListener 'data', @stderrCallback

  start: (serverPath, pattern, next) =>
    throw Err.ArgumentNullException('serverPath required') unless serverPath?
    throw Err.ArgumentNullException('pattern required') unless pattern?

    @spawnServer = Spawn 'coffee', [serverPath]

    @startOutputMon()
    @waitForOutput pattern, next

  stop: (next) =>
    return next() unless @spawnServer?
    
    @stopOutputMon()

    @spawnServer.once 'exit', (code, signal) =>
      next(null, code, signal)

    @spawnServer.kill 'SIGINT'
    @spawnServer = null

spawnServer = coreClass.get()

module.exports.start = (serverPath, pattern, next) =>
  spawnServer.start serverPath, pattern, ()=>
    next() if next? 

module.exports.stop = (next) =>
  spawnServer.stop (err, code, signal) =>
    next(err, code, signal) if next? 

module.exports.serverProcess = () =>
  return spawnServer.spawnServer
