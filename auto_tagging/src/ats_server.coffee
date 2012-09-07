Log    = require 'tern.logger'
Broker = require('tern.queue').Broker
Domain = require 'domain'

module.exports.start = (argv) ->
  serverDomain = Domain.create()

  # Uncaught error trap
  serverDomain.on 'error', (err) ->
    Log.error "Uncaught error on Auto Tagging Service: #{err.toString()}\r\n#{err.stack}"

  serverDomain.run ->

    broker = new Broker argv
    Log.notice "Auto Tagging Service started: [router]:#{argv.router} and [dealer]:#{argv.dealer}"

    # Register workers
    #require('./zmq_workers/token_auth').register argv