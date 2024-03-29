process.title = 'Tern.MediaQueues'

BrokersHelper = require('tern.central_config').BrokersHelper
ConfigGetter = require './config_getter'

ConfigGetter.init 'MediaQueues', (err, argv) ->
  console.error err.toString(), err.stack if err?

  console.log require('tern.logo').MediaQueues('0.1')

  Log = require 'tern.logger'
  Broker = require('tern.queue').Broker

  broker = null

  options = {}

  for zone, value of argv.queues
    #console.log zone, value
    options.router = BrokersHelper.getEndpointFromConfigValue value.router.bind
    options.dealer = BrokersHelper.getEndpointFromConfigValue value.dealer.bind

    options.from = argv.current
    options.to = zone

    broker = new Broker(options)

    options = broker.options
    Log.notice "Media Queues: #{options.from} to #{options.to} - [router]:#{options.router} and [dealer]:#{options.dealer}"
