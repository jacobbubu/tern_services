uuid = require "node-uuid"
ZMQ  = require "zmq"

EventEmitter = require("events").EventEmitter
class Handle extends EventEmitter
  constructor: (@id, @callback) ->

module.exports = class Sender
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
    endpoint = @options.router or "ipc:///tmp/tern.reqres-router"
    @socket = ZMQ.socket "dealer"
    @socket.on "message", @_message
    @socket.connect endpoint

  _completed: (task) ->
    handle = @_getHandle task.id
    handle.callback? null, task.data
    handle.emit "complete", task.data unless handle.listeners("complete").length is 0
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