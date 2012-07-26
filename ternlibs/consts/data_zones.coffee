Config = require('../lib/config')

dataZones = {}

# Set config file change monitor
Config.watch Config, 'DataZones', (object, propertyName, priorValue, newValue) ->
  Log.info "DataZones config changed: '#{propertyName}' changed from '#{priorValue}' to '#{newValue}'"
  configInit()

configInit = ->
  dataZones = Config.DataZones

configInit()

module.exports = dataZones