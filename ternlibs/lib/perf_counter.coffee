###
# Declare config module for default values setting and change monitoring
###
Config  = require "./config"
Log     = require "./logger"

###
# We wrapped node-statsd here
###
StatsD  = (require './statsd').StatsD

###
# Internal variables
###
internals = 
  statsd  : null


###
# Initialization
###
initialize = do ->

  # Set default configuration values
  Config.setModuleDefaults 'PerfCounter', {
    host: 'localhost'
    port: 8125
  }

  # Set config file change monitor
  Config.watch Config, 'PerfCounter', (object, propertyName, priorValue, newValue) ->
    Log.info "PerfCounter config changed: '#{propertyName}' changed from '#{priorValue}' to '#{newValue}'"
    internals.statsd = new StatsD(Config.PerfCounter.host, Config.PerfCounter.port)

  internals.statsd = new StatsD(Config.PerfCounter.host, Config.PerfCounter.port)

exports.increment     = -> return internals.statsd.increment.apply(internals.statsd, arguments)
exports.decrement     = -> return internals.statsd.decrement.apply(internals.statsd, arguments)
exports.timing        = -> return internals.statsd.timing.apply(internals.statsd, arguments)
exports.gauges        = -> return internals.statsd.gauges.apply(internals.statsd, arguments)
exports.update_stats  = -> return internals.statsd.update_stats.apply(internals.statsd, arguments)