zmq         = require 'zmq'
Path        = require 'path'
Coffee      = require 'coffee-script'
FS          = require 'fs'
WatchFolder = require 'watch'
Utils       = require './utils'

module.exports = class Server
  constructor: ( @options = {} ) ->
    @configObject = null
    @configFileName = Path.resolve __dirname, @options.configFilename or '../config_file/config.coffee' 
    @configFileName = FS.realpathSync @configFileName
    @_readConfigFile @configFileName

    @_initSockets()
    @_bindResponder()
    @_bindPublisher  =>
      @_watchConfigFile @configFileName

  _readConfigFile: (fileName) =>
    # delete cached config
    delete require.cache[fileName]

    try
      newConfig = require(fileName)
    catch err      
      console.error 'Configuration reading failed:', err.toString, err.stack
      if @configObject is null
        throw err
      return

    if @configObject is null
      @configObject = newConfig
    else
      unless Utils.deepEquals newConfig, @configObject
        @configObject = newConfig
        @publisher.send 'config'+ ' ' + JSON.stringify newConfig

  _initSockets: ->
    @responder = zmq.socket "rep"
    @publisher = zmq.socket "pub"

  _bindResponder: (next) ->
    endpoint = @options.responder or "ipc:///tmp/configServer-req"
    @responder.on "message", @_responderRx
    @responder.bind endpoint, =>
      console.log "Responder listening on %s", endpoint
      next? and next()

  _bindPublisher: (next) ->
    endpoint = @options.publisher or "ipc:///tmp/configServer-sub"
    #@publisher.on "message", @_publisherRx
    @publisher.bind endpoint, =>      
      console.log "Publisher listening on %s", endpoint 
      next? and next()

  _watchConfigFile: (fileName) ->
    dirName = Path.dirname fileName
    WatchFolder.createMonitor dirName, { persistent: true, interval: 2003 }, (monitor) =>

      isTheFile = (f, fileName) ->        
        changedFile = Path.basename(f) + '.' + Path.extname(f)
        originalFile = Path.basename(fileName) + '.' + Path.extname(fileName)
        changedFile is originalFile
 
      monitor.on "created", (f, stat) =>
        if isTheFile f, fileName
          console.log 'Config file created'
          @_readConfigFile fileName

      monitor.on "changed", (f, curr, prev) =>
        if isTheFile f, fileName
          console.log 'Config file changed'
          @_readConfigFile fileName

      monitor.on "removed", (f, stat) =>
        if isTheFile f, fileName
          console.log 'Config file removed'

  _responderRx: (payload) =>
    message = payload.toString()

    if message is 'getConfig'
      @responder.send JSON.stringify @configObject

  _publisherRx: (payload) =>