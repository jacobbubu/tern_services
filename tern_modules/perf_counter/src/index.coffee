Log           = require "tern.logger"
BrokersHelper = require('tern.central_config').BrokersHelper

###
# We wrapped node-statsd here
###
StatsD  = new require('tern.statsd')

###
# Internal variables
###
internals = 
  statsd  : null
  configObj   : null
  config      : null

###
# Initialization
###
initialize = do ->

  internals.configObj = BrokersHelper.getConfig('perfCounter')

  if internals.configObj?

    internals.config = internals.configObj.value

    internals.configObj.on 'changed', (oldValue, newValue) ->
      console.log 'perfCounter config changed'
      internals.config = newValue
      internals.statsd = new StatsD(internals.config.host, internals.config.port)

  else
    internals.config = 
      host: 'localhost'
      port: 8125

  internals.statsd = new StatsD(internals.config.host, internals.config.port)

exports.increment     = -> return internals.statsd.increment.apply(internals.statsd, arguments)
exports.decrement     = -> return internals.statsd.decrement.apply(internals.statsd, arguments)
exports.timing        = -> return internals.statsd.timing.apply(internals.statsd, arguments)
exports.gauges        = -> return internals.statsd.gauges.apply(internals.statsd, arguments)
exports.update_stats  = -> return internals.statsd.update_stats.apply(internals.statsd, arguments)