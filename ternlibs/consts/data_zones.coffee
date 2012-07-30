Config = require('../lib/config')

dataZones = {}

# Set config file change monitor
#Config.watch Config, 'DataZones', (object, propertyName, priorValue, newValue) ->
#  Log.info "DataZones config changed"
#  configInit()

configInit = ->
  dataZones = Config.DataZones

configInit()

module.exports = dataZones