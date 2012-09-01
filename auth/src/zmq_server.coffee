Log    = require 'tern.logger'
Broker = require('tern.zmq_reqres').Broker
Domain = require 'domain'

module.exports.start = (argv) ->
  serverDomain = Domain.create()

  # Uncaught error trap
  serverDomain.on 'error', (err) ->
    Log.error "Uncaught error on Auth. ZMQ Server: #{err.toString()}\r\n#{err.stack}"

  serverDomain.run ->

    broker = new Broker argv
    Log.notice "Auth. ZMQ Server started: [router]:#{argv.router} and [dealer]:#{argv.dealer}"

    # Register workers
    require('./zmq_workers/token_auth').register argv