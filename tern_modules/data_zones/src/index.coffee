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
      console.log "current datazone config changed from '#{oldValue}' to '#{newValue}'"
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

module.exports.get = (datazone) ->
  init() unless configObject?
  dataZones[datazone]

module.exports.getWebSocketBind = (datazone) ->
  init() unless configObject?
  dataZones[datazone].websocket.bind

module.exports.getWebSocketConnect = (datazone) ->
  init() unless configObject?
  dataZones[datazone].websocket.connect

module.exports.getMediaBind = (datazone) ->
  init() unless configObject?
  dataZones[datazone].media.bind

module.exports.getMediaConnect = (datazone) ->
  init() unless configObject?
  dataZones[datazone].media.connect

module.exports.getZMQBind = (datazone) ->
  init() unless configObject?
  dataZones[datazone].zmq.bind

module.exports.getZMQConnect = (datazone) ->
  init() unless configObject?
  dataZones[datazone].zmq.connect
