Utils           = require('tern.utils')
ZMQResponder    = require('tern.zmq_helper').zmq_responder
ZMQStatusCodes  = require('tern.zmq_helper').zmq_status_codes
ZMQKey          = require('tern.zmq_helper').zmq_key
ZMQ             = require 'zmq'

uuid         = require "node-uuid"

class Broker
  constructor: ( @options={} ) ->
    @_initSockets()

  _initSockets: ->
    @router = ZMQ.socket "router"
    @dealer = ZMQ.socket "dealer"

  _bindRouter: ->
    endpoint = @options.router or "ipc:///tmp/ternServer-router"
    @router.on "message", @_routerRx
    @router.bindSync endpoint

  _bindDealer: ->
    endpoint = @options.router or "ipc:///tmp/ternServer-dealer"
    @dealer.on "message", @_dealerRx
    @dealer.bindSync endpoint

  _routerRx: (envelopes..., payload) =>
    @_dealerTx envelopes, payload

  _dealerTx: (envelopes, payload) ->
    @dealer.send [envelopes, payload]
    
  _dealerRx: (envelopes..., payload) =>
    @_routerTx envelopes, payload

  _routerTx: (envelopes, payload) ->
    @router.send [envelopes, payload]

class Responder
  constructor: ( @options={} ) ->
    @_connect()

  _connect: ->
    endpoint = @options.dealer or "ipc:///tmp/ternServer-dealer"
    @socket = ZMQ.socket "rep"
    @socket.on "message", @_message
    @socket.connect endpoint

  _message: (payload) =>

    badMessage = (e) ->
      ZMQResponder.send serverSock, ZMQStatusCodes.BadRequest, messageObj

    internalError = (e) ->
      ZMQResponder serverSock, ZMQStatusCodes.InternalServerError, messageObj

    try
      message = Utils.decryptAndUnlzf payload, ZMQKey.key_iv
      try
        messageObj = JSON.parse message

        response =
          response:
            status: ZMQStatusCodes.OK

        ZMQResponder.send serverSock, messageObj, response
      catch e
        internalError e, message
    catch e
      badMessage e

EventEmitter = require("events").EventEmitter
class Handle extends EventEmitter
  constructor: (@id, @callback) ->

class Sender
  constructor: ( @options={} ) ->
    @handles = {}
    @_connect()

  close: -> @socket.close()

  send: (name, data, next) ->
    handle = @_addHandle uuid(), next
    payload = JSON.stringify id: handle.id, request: name, data: data
    @socket.send [new Buffer(""), payload]
    handle

  _connect: ->
    endpoint = @options.router or "ipc:///tmp/ternServer-dealer"
    @socket = ZMQ.socket "dealer"
    @socket.on "message", @_message
    @socket.connect endpoint

  _completed: (task) ->
    handle = @_getHandle task.id
    handle.callback? null, task.data
    handle.emit "complete", task.data
    @_removeHandle handle

  _failed: (task) ->
    handle = @_getHandle task.id
    handle.callback? task.data
    handle.emit "error", task.data unless handle.listeners("error").length is 0
    @_removeHandle handle

  _getHandle: (id) -> @handles[id]

  _addHandle: (id, next) ->
    handle = new Handle id, next
    @handles[id] = handle
    handle

  _removeHandle: (handle) ->
    delete @handles[handle.id]

  _message: (envelopes..., payload) =>
    task = JSON.parse payload
    switch task.response
      when "completed"
        @_completed task
      when "failed"
        @_failed task
      else
        throw new Error("Unknown response '#{task.response}'")


broker = new Broker()
responder = new Responder()

###
endpoint = process.argv[2]
unless endpoint?
  console.log "Usgae: coffee zmqserver tcp://127.0.0.1:3000"
  process.exit(0)
else
  serverSock = ZMQ.socket('rep')

  serverSock.bind endpoint, ->
    console.log "Auth. ZMQ Server is listening on #{endpoint} "

  serverSock.on 'message', (data) ->

    badMessage = (e) ->
      console.error "ZMQ: #{e.toString()}\r\n#{e.stack}"
      ZMQResponder.send serverSock, ZMQStatusCodes.BadRequest, messageObj

    internalError = (e) ->
      console.error "ZMQ: #{e.toString()}\r\n#{e.stack}\r\n#{message}"
      ZMQResponder serverSock, ZMQStatusCodes.InternalServerError, messageObj

    try
      message = Utils.decryptAndUnlzf data, ZMQKey.key_iv
      try
        messageObj = JSON.parse message

        response =
          response:
            status: ZMQStatusCodes.OK

        ZMQResponder.send serverSock, messageObj, response
      catch e
        internalError e, message
    catch e
      badMessage e
###