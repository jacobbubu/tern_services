Log             = require('ternlibs').logger
Perf            = require('ternlibs').perf_counter
Utils           = require('ternlibs').utils
ZMQResponder    = require('ternlibs').zmq_responder
ZMQStatusCodes  = require('ternlibs').zmq_status_codes
ZMQ             = require 'zmq'
ZMQHandler      = require './zmqfacets/zmq_message_handler'
Domain          = require 'domain'

module.exports.start = (argv) ->
  serverDomain = Domain.create()

  # Uncaught error trap
  serverDomain.on 'error', (err) ->
    Log.error "Uncaught error on Auth. ZMQ Server: #{err.toString()}\r\n#{err.stack}"

  serverDomain.run ->
    endpoint = "tcp://" + argv.zmq_host + ":" + argv.zmq_port
    serverSock = ZMQ.socket('rep')

    serverSock.bind endpoint, ->
      Log.notice "Auth. ZMQ Server is listening on #{endpoint} "

    serverSock.on 'message', (data) ->

      badMessage = (e) ->
        Log.error "ZMQ: #{e.toString()}\r\n#{e.stack}"
        ZMQResponder.send serverSock, ZMQStatusCodes.BadRequest, messageObj

      internalError = (e) ->
        Log.error "ZMQ: #{e.toString()}\r\n#{e.stack}\r\n#{message}"
        ZMQResponder serverSock, ZMQStatusCodes.InternalServerError, messageObj

      try
        message = Utils.decryptAndUnlzf data
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