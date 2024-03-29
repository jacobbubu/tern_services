zmq     = require 'zmq'
Utils   = require 'tern.utils'
Err     = require 'tern.exceptions'
ZMQKey  = require './zmq_key'

class ZMQSender

  #@identityCounter = 0

  constructor: (@endpoint, @key_iv, @identity, @defaultTimeout) ->
    
    throw new Error "Endpoint required." unless @endpoint?
    @key_iv = @key_iv ? ZMQKey.key_iv

    #ZMQSender.identityCounter++

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
    #@socket.identity = @identity ? ['tern', process.pid.toString(), ZMQSender.identityCounter.toString()].join '.'

    @socket.identity = @identity if @identity?

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
    newTS = Utils.getTimestamp 'zmq_sender'

    message = 
      req_ts: newTS
      request: arguments[0]
    
    strMessage = JSON.stringify message

    if arguments.length < 3
      timeout = @defaultTimeout
      next = arguments[1]
    else
      timeout = timeout * 1000
      next = arguments[2]
    
    #next.req_ts = newTS if next?
    
    buffer = Utils.lzfAndEncrypt strMessage, @key_iv
    if next?
      @_requests[newTS] = { 'next': next, 'expire_at': +new Date + timeout }
      unless @cleanTimer?
        @cleanTimer = setInterval =>
                        @_clean()
                        if Object.keys(@_requests).length is 0
                          clearInterval @cleanTimer
                          @cleanTimer = null
                      , 1000

    @socket.send buffer

  close: () ->
    @socket.close() if @socket?

module.exports = ZMQSender
