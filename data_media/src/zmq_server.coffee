Log             = require 'tern.logger'
Perf            = require 'tern.perf_counter'
Utils           = require 'tern.utils'

ZMQResponder    = require('tern.zmq_helper').zmq_responder
ZMQStatusCodes  = require('tern.zmq_helper').zmq_status_codes
ZMQKey          = require('tern.zmq_helper').zmq_key
ZMQ             = require 'zmq'
ZMQHandler      = require './zmqfacets/zmq_message_handler'

Domain          = require 'domain'

module.exports.start = (argv) ->
  serverDomain = Domain.create()

  # Uncaught error trap
  serverDomain.on 'error', (err) ->
    Log.error "Uncaught error on Data ZMQ Server: #{err.toString()}\r\n#{err.stack}"

  serverDomain.run ->
    try
      endpoint = "tcp://#{argv.host}:#{argv.port}"
      serverSock = ZMQ.socket('rep')

      serverSock.bind endpoint, ->
        Log.notice "Data ZMQ Server is listening on #{endpoint} "

    serverSock.on 'message', (data) ->

      badMessage = (e) ->
        Log.error "ZMQ: #{e.toString()}\r\n#{e.stack}"
        ZMQResponder.send serverSock, ZMQStatusCodes.BadRequest, messageObj

      internalError = (e) ->
        Log.error "ZMQ: #{e.toString()}\r\n#{e.stack}\r\n#{message}"
        ZMQResponder serverSock, ZMQStatusCodes.InternalServerError, messageObj

      try
        message = Utils.decryptAndUnlzf data, ZMQKey.key_iv
        try
          messageObj = JSON.parse message
  
          ZMQHandler.processMessage messageObj, (err, res) ->
            if err?
              internalError err
            else
              try
                ZMQResponder.send serverSock, messageObj, res
              catch e
                Log.error "ZMQ Error sending response:\r\n#{e.toString()}\r\n#{e.stack}\r\n#{message}"
        catch e
          internalError e, message
      catch e
        badMessage e