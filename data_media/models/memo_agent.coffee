Config        = require('ternlibs').config
Log           = require('ternlibs').logger
Err           = require('ternlibs').exceptions
DB            = require('ternlibs').database
Cache         = require('ternlibs').cache
Utils         = require('ternlibs').utils
DataZones     = require('ternlibs').consts.data_zones

ZMQSender     = require('ternlibs').zmq_sender
DefaultPorts  = require('ternlibs').default_ports

MediaFile     = require('../models/media_file_mod')

###
# Configuration
# This configuration could take effect on the fly
#
# host: address of Central Auth. Service (ZMQ Req/Res)
# port: port of Central Auth. Service
#
###
Config.setModuleDefaults 'CentralAuth', {
  "host": DefaultPorts.CentralAuthZMQ.host
  "port": DefaultPorts.CentralAuthZMQ.port
}

# Set config file change monitor
Config.watch Config, 'CentralAuth', (object, propertyName, priorValue, newValue) ->
  Log.info "CentralAuth config changed: '#{propertyName}' changed from '#{priorValue}' to '#{newValue}'"
  configInit()

configInit = ->
  config = Config.CentralAuth
  authSender = new ZMQSender("tcp://#{config.host}:#{config.port}")
  
  tokenCacheModel = coreClass.get()
  tokenCacheModel.authSender = authSender

configInit()


class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _MemoAgent

class _MemoAgent
  constructor: () ->
    @db = DB.getDB 'UserDataDB'
    @senders = {}

  getSender: (dataZone) ->
    unless @senders[dataZone]?
      endpoint = DataZones[dataZone]      
      throw Err.ArgumentUnsupportedException("#{dataZone} does not exist") unless endpoint? 

      @senders[dataZone] = new ZMQSender(endpoint)
      return @senders[dataZone]

  mediaWriteback: (dataZone, mid, uri, next) ->
    # mid is media_id
    try
      sender = @getSender(dataZone)    

      message = 
        method: "mediaWriteback"
        data:
          'mid': mid
          'uri': uri

      sender.send message, (err, response) =>
        return next err if next? and err?

        switch response.response.status
          when 0
            # Taking sharing list back.
            result = response.response.result
          else
            # Delete inexsisting media
            MediaFile.unlink mid, (err) ->
              Log.error "Error delete media ('#{mid}'): " + err.toString() if err?

    catch e
      Log.error "Error mediaWriteback. dataZone: #{dataZone}, mid: #{media_id}, uri: #{uri})" + e.toString()
      next e if next?

###
# Modulereturn Exports
###
memoAgent = coreClass.get()

