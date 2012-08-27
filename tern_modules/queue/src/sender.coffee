uuid         = require "node-uuid"
zmq          = require 'zmq'
EventEmitter = require("events").EventEmitter

class Handle extends EventEmitter
  constructor: (@id, @next) ->

module.exports = class Sender
  constructor: ( @options={} )->
    @handles = {}
    @_connect()
  
  _connect: ->
    endpoint = @options.router or "ipc:///tmp/queueServer-router"
    @socket = zmq.socket "dealer"
    @socket.on "message", @_message
    @socket.connect endpoint

  _getHandle: (id) -> @handles[id]

  _addHandle: (id, next) ->
    handle = new Handle id, next
    @handles[id] = handle
    handle

  _removeHandle: (handle) ->
    delete @handles[handle.id]

  _submitted: (task) ->
    handle = @_getHandle task.id
    handle.emit "submit" unless handle.listeners("submit").length is 0

  _completed: (task) ->
    handle = @_getHandle task.id
    handle.next? null, task.data
    handle.emit "complete", task.data unless handle.listeners("complete").length is 0
    @_removeHandle handle

  _failed: (task) ->
    handle = @_getHandle task.id
    handle.next? task.data
    handle.emit "error", task.data unless handle.listeners("error").length is 0
    @_removeHandle handle

  _message: (envelopes..., payload) =>
    task = JSON.parse payload
    switch task.response
      when "submitted"
        @_submitted task
      when "completed"
        @_completed task
      when "failed"
        @_failed task        
      else
        throw new Error("Unknown response '#{task.response}'")

  send: (name, data, next) ->
    handle = @_addHandle uuid(), next
    payload = JSON.stringify id: handle.id, request: name, data: data
    @socket.send [new Buffer(""), payload]
    handle

  # Closes the connection to the queue server.  
  close: -> @socket.close()
