zmq          = require "zmq"
async        = require "async"
EventEmitter = require("events").EventEmitter
Queue        = require "./queue"

module.exports = class Broker extends EventEmitter
  constructor: ( @options = {} ) ->
    @_initStore()
    @_initSockets()
    @_bindDealer()
    @_bindRouter()
    @_resendExistingMessages()
        
  _initStore: ->
    Store  = require "./store"    
    @store = new Store @options.store?.options
    @queue = new Queue (task, next) =>
      @store.write task.id, JSON.stringify(task), next
    , @store?.maxConnections or 1

  _initSockets: ->
    @router = zmq.socket "router"
    @dealer = zmq.socket "dealer"

  _bindRouter: ->
    endpoint = @options.router or "ipc:///tmp/queueServer-router"
    @router.on "message", @_routerRx
    @router.bindSync endpoint

  _bindDealer: ->
    endpoint = @options.dealer or "ipc:///tmp/queueServer-dealer"
    @dealer.on "message", @_dealerRx
    @dealer.bind endpoint

  _routerRx: (envelopes..., payload) =>
    task = JSON.parse payload

    @queue.push task, (error) =>
      if err?
        @_routerTx envelopes, id: task.id, response: "failed", data: err
        console.error "Failed to write task: %s (%s)", task.id, error
      else
        @_dealerTx envelopes, payload
        @_routerTx envelopes, id: task.id, response: "submitted"
        console.log "Task submitted: %s", task.id

  _dealerTx: (envelopes, payload) =>
    unless payload instanceof Buffer
      payload = JSON.stringify payload

    @dealer.send [envelopes, payload]

  _dealerRx: (envelopes..., payload) =>
    task = JSON.parse payload

    switch task.response
      when "completed"
        console.log "Task completed: %s", task.id
      when "failed"
        console.error "Task failed: %s (%s)", task.id, task.data
      else
        throw new Error("Unknown response '#{task.response}'")

    @store.delete task.id, (err) =>
      if err?
        console.error "Failed to delete task: %s (%s)", task.id, err
      else
        @_routerTx envelopes, payload

  _routerTx: (envelopes, payload) ->
    unless payload instanceof Buffer
      payload = JSON.stringify payload
    @router.send [envelopes, payload]

  _resendExistingMessages: =>
    @store.keys (err, ids) =>
      throw err if err?
      async.forEachSeries ids, @_resendMessage, (err) =>
        throw err if err?    

  _resendMessage: (id, next) =>
    @store.read id, (err, data) =>
      if err?
        next err
      else
        @_dealerTx new Buffer(""), new Buffer(data)
        #console.log "Task submitted: %s", (JSON.parse data).id
        next null