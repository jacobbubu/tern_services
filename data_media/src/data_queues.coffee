process.title = 'Tern.DataQueues'

ConfigGetter = require './config_getter'

ConfigGetter.init 'DataQueues', (err, argv) ->
  console.error err.toString(), err.stack if err?

  console.log require('tern.logo').DataQueues('0.1')

  Log = require 'tern.logger'
  Broker = require('tern.queue').Broker

  broker = null

  options = {}

  for zone, value of argv.queues
    #console.log zone, value
    {host, port} = value.router.bind
    options.router = "tcp://#{host}:#{port}"

    {host, port} = value.dealer.bind
    options.dealer = "tcp://#{host}:#{port}"

    options.from = argv.current
    options.to = zone

    broker = new Broker(options)

    options = broker.options
    Log.notice "Data Queues: #{options.from} to #{options.to} - [router]:#{options.router} and [dealer]:#{options.dealer}"