zmq     = require 'zmq'
Utils   = require('ternlibs').utils

class RequestSender
  constructor: (@endpoint, @key_iv, @defaultTimeout) ->
    
    throw new Error "Endpoint required." unless @endpoint?
    throw new Error "Key_iv required." unless @key_iv?

    @defaultTimeout = 60 * 1000 unless @defaultTimeout?
    @socket = zmq.socket('req')
    @cleanTimer = null
    @_connect()

  _clean: =>
    for k, v of @_requests
      if v.expire_at < +new Date
        next = v.next
        delete @_requests[k]
        err = new Error("Request to '#{@endpoint}' is timeout.")
        err.reason = 'TIMEOUT'
        next err

  _connect: ->
    @counter = process.pid * 10000

    @socket.identity = "boy one" + process.pid
    @_requests = {}

    @socket.connect @endpoint
  
    #Receiver
    @socket.on 'message', (buffer) =>

      Utils.decryptAndUncompress buffer, @key_iv, (err, message) =>
        messageObj = JSON.parse message
        req_ts = messageObj.req_ts
        body = messageObj.body

        if @_requests[req_ts]?
          next = @_requests[req_ts].next
          delete @_requests[req_ts]
          next null, messageObj
      
  send: () ->
    message = 
      req_ts: @counter
      body: arguments[0]
    
    strMessage = JSON.stringify message

    if arguments.length < 3
      timeout = @defaultTimeout
      next = arguments[1]
    else
      timeout = timeout * 1000
      next = arguments[2]
    
    next.counter = @counter if next?
    
    @counter++

    Utils.compressAndEncrypt strMessage, @key_iv, (err, buffer) =>
      if err?
        next err if next?
      else  
        if next?
          @_requests[next.counter] = { 'next': next, 'expire_at': +new Date + timeout }
          unless @cleanTimer?
            @cleanTimer = setInterval =>
                            @_clean()
                            if Object.keys(@_requests).length is 0
                              clearInterval @cleanTimer
                              @cleanTimer = null
                          , 1000

        @socket.send buffer

module.exports = RequestSender

