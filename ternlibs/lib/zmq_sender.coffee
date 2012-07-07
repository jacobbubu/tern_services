zmq     = require 'zmq'
Utils   = require './utils'
Err     = require './exceptions'

class ZMQSender

  @identityCounter = 0

  constructor: (@endpoint, @key_iv, @identity, @defaultTimeout) ->
    
    throw new Error "Endpoint required." unless @endpoint?
    throw new Error "Key_iv required." unless @key_iv?

    ZMQSender.identityCounter++

    @defaultTimeout = 60 * 1000 unless @defaultTimeout?
    @socket = zmq.socket('req')
    @cleanTimer = null
    @_connect()

  _clean: =>
    for k, v of @_requests
      if v.expire_at < +new Date
        next = v.next
        delete @_requests[k]

        next Err.TimeoutException "Request to '#{@endpoint}' is timeout."

  _connect: ->
    @counter = process.pid * 10000

    @socket.identity = @identity ? ['tern', process.pid.toString(), ZMQSender.identityCounter.toString()].join '.'
    @_requests = {}

    @socket.connect @endpoint
  
    #Receiver
    @socket.on 'message', (buffer) =>

      message = Utils.decryptAndUnlzf buffer, @key_iv
      messageObj = JSON.parse message
      req_ts = messageObj.req_ts

      if @_requests[req_ts]?
        next = @_requests[req_ts].next
        delete @_requests[req_ts]
        next null, messageObj
      
  ###
  # Send a message to socket
  # Params: 
  #   1st: a message object
  #   2nd: timeout (optional)
  #   3rd: a callback (optional)
  ###
  send: () ->
    message = 
      req_ts: @counter
      request: arguments[0]
    
    strMessage = JSON.stringify message

    if arguments.length < 3
      timeout = @defaultTimeout
      next = arguments[1]
    else
      timeout = timeout * 1000
      next = arguments[2]
    
    next.counter = @counter if next?
    
    @counter++

    buffer = Utils.lzfAndEncrypt strMessage, @key_iv
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

module.exports = ZMQSender
