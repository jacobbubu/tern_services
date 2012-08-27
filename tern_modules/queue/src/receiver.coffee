zmq = require "zmq"

# A queue message reader

module.exports = class Receiver
  constructor: ( @options = {} ) ->
    @workerClasses = {}
    @_connect()

  # Closes the connection to the broker.
  close: ->
    @socket.close()

  # Registers a reader with the given name and class.
  registerWorker: (name, workerClass) ->
    @workerClasses[name] = workerClass

  _connect: ->
    endpoint = @options.dealer or "ipc:///tmp/queueServer-dealer"
    @socket = zmq.socket "rep"
    @socket.on "message", @_message
    @socket.connect endpoint

  _message: (payload) =>
    task = JSON.parse payload
    @_runTask task, (err, data) =>
      payload = if err?
        JSON.stringify id: task.id, response: "failed", data: err.toString()
      else
        JSON.stringify id: task.id, response: "completed", data: data
      @socket.send payload

  _runTask: (task, next) ->
    try
      Task = @workerClasses[task.request]
      throw new Error("Unknown task '#{task.request}'") unless Task?
      instance = new Task this
      instance.run task.data, next
    catch err
      next err
