ZMQ = require "zmq"

module.exports = class Responder
  constructor: ( @options = {} ) ->
    @workerClasses = {}
    @_connect()

    @registerWorker 'Reverse', require './workers/reverse'

  # Closes the connection to the broker.
  close: ->
    @socket.close()

  # Registers a reader with the given name and class.
  registerWorker: (name, workerClass) ->
    @workerClasses[name] = workerClass

  _connect: ->
    endpoint = @options.dealer or "ipc:///tmp/tern.reqres-dealer"
    @socket = ZMQ.socket "rep"
    @socket.on "message", @_message
    @socket.connect endpoint

  _message: (payload) =>
    task = JSON.parse payload
    @_runTask task, (err, data) =>
      retPayload = if err?
        JSON.stringify id: task.id, response: "failed", data: err.toString()
      else
        JSON.stringify id: task.id, response: "completed", data: data
      @socket.send retPayload

  _runTask: (task, next) =>
    try
      workerClass = @workerClasses[task.request]
      throw new Error("Unknown task #{JSON.stringify task}") unless workerClass?
      instance = new workerClass this
      instance.run task.data, next
    catch err
      next err
