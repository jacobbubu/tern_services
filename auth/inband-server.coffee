Config        = require('ternlibs').config
Log           = require('ternlibs').logger
Perf          = require('ternlibs').perf_counter
ZMQ           = require 'zmq'
Utils         = require('ternlibs').utils
ZMQUtils      = require './zmqfacets/zmq_utils'
ZMQAuth       = require './zmqfacets/zmq_auth'

###
# Configuration
###
Config.setModuleDefaults 'InbandServer', {
  "host": '127.0.0.1'
  "port": 3001
}

endpoint = "tcp://" + Config.InbandServer.host + ":" + Config.InbandServer.port
serverSock = ZMQ.socket('rep')

serverSock.bindSync endpoint
Log.notice "Auth. In-band Server is listening on port " + Config.InbandServer.port

serverSock.on 'message', (data) ->

  badMessage = (e) ->
    Log.error "In-band: " + e.toString()
    serverSock.send 'Bad message format'

  internalError = (e, message) ->
    Log.error "In-band: " + e.toString() + " req: #{message}"
    serverSock.send 'Internal error'

  try
    message = Utils.decryptAndUnlzf data, ZMQUtils.key_iv
    try
      messageObj = JSON.parse message      
      ZMQAuth.processMessage messageObj, (err, res) ->
        if err?
          internalError err, message
        else
          try
            strResponse = JSON.stringify(res)
            buffer = Utils.lzfAndEncrypt strResponse, ZMQUtils.key_iv            
            serverSock.send buffer
            Log.info "In-band: req: #{message} res: #{JSON.stringify(res)} Length: #{new Buffer(strResponse).length}/#{buffer.length}"
          catch e
            internalError e, message
    catch e
      internalError e, message
  catch e
    badMessage e