ZMQ = require 'zmq'

module.exports = class Broker
  constructor: ( @options = {} ) ->
    @_initSockets()
    @_bindRouter()
    @_bindDealer()

  _initSockets: ->
    @router = ZMQ.socket "router"
    @dealer = ZMQ.socket "dealer"

  _bindRouter: ->
    endpoint = @options.router or "ipc:///tmp/tern.reqres-router"
    @router.on "message", @_routerRx
    @router.bindSync endpoint

  _bindDealer: ->
    endpoint = @options.dealer or "ipc:///tmp/tern.reqres-dealer"
    @dealer.on "message", @_dealerRx
    @dealer.bindSync endpoint

  _routerRx: (envelopes..., payload) =>
    @dealer.send [envelopes, payload]
        
  _dealerRx: (envelopes..., payload) =>
    @router.send [envelopes, payload]
