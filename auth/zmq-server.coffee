Log           = require('ternlibs').logger
Perf          = require('ternlibs').perf_counter
ZMQ           = require 'zmq'
Utils         = require('ternlibs').utils
ZMQAuth       = require './zmqfacets/zmq_auth'
Domain        = require 'domain'

module.exports.start = (argv) ->
  serverDomain = Domain.create()

  # Uncaught error trap
  serverDomain.on 'error', (err) ->
    Log.error 'Uncaught error on Auth. In-band Server: ', err.toString()

  serverDomain.run ->
    endpoint = "tcp://" + argv.zmq_host + ":" + argv.zmq_port
    serverSock = ZMQ.socket('rep')

    serverSock.bind endpoint, ->
      Log.notice "Auth. ZMQ Server is listening on #{endpoint} "

    serverSock.on 'message', (data) ->

      badMessage = (e) ->
        Log.error "ZMQ: " + e.toString()
        serverSock.send 'Bad message format'

      internalError = (e, message) ->
        Log.error "ZMQ: " + e.toString() + " req: #{message}"
        serverSock.send 'Internal error'

      try
        message = Utils.decryptAndUnlzf data
        try
          messageObj = JSON.parse message      
          ZMQAuth.processMessage messageObj, (err, res) ->
            if err?
              internalError err, message
            else
              try
                strResponse = JSON.stringify(res)
                resBuffer = Utils.lzfAndEncrypt strResponse
                serverSock.send resBuffer
                Log.info "ZMQ: req: #{message} res: #{JSON.stringify(res)} Length: #{new Buffer(strResponse).length}/#{resBuffer.length}"
              catch e
                internalError e, message
        catch e
          internalError e, message
      catch e
        badMessage e