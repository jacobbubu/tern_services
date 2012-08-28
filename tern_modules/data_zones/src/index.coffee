BrokersHelper = require('tern.central_config').BrokersHelper

configObject = null
dataZones = null
currentObj = null
currentDataZone = ''

init = -> 
  currentObj = BrokersHelper.getConfig 'dataZone'
  if currentObj?
    currentDataZone = currentObj.value

    currentObj.on 'changed', (oldValue, newValue) ->
      console.log "current dataZone config changed from '#{oldValue}' to '#{newValue}'"
      currentDataZone = newValue
  else
    throw new Error("Can not get 'dataZone' from config brokers")

  configObject = BrokersHelper.getConfig 'dataZones'
  if configObject?
    dataZones = configObject.value

    configObject.on 'changed', (oldValue, newValue) ->
      console.log 'dataZones config changed'
      dataZones = newValue
  else
    throw new Error("Can not get 'dataZones' from config brokers")

module.exports.currentDataZone = () ->
  init() unless currentObj?
  return currentDataZone

module.exports.get = (dataZone) ->
  init() unless configObject?
  dataZones[dataZone]

module.exports.getWebSocketBind = (dataZone) ->
  init() unless configObject?
  dataZones[dataZone].websocket.bind

module.exports.getWebSocketConnect = (dataZone) ->
  init() unless configObject?
  dataZones[dataZone].websocket.connect

module.exports.getMediaBind = (dataZone) ->
  init() unless configObject?
  dataZones[dataZone].media.bind

module.exports.getMediaConnect = (dataZone) ->
  init() unless configObject?
  dataZones[dataZone].media.connect

module.exports.getZMQBind = (dataZone) ->
  init() unless configObject?
  dataZones[dataZone].zmq.bind

module.exports.getZMQConnect = (dataZone) ->
  init() unless configObject?
  dataZones[dataZone].zmq.connect
