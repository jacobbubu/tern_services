Datazones = require 'tern.data_zones'
Sender = require('tern.queue').Sender

dataQueuesSenders = {}
mediaQueuesSenders = {}

getDataQueuesSender = (dataZone) ->
  unless dataQueuesSenders[dataZone]?
    current = Datazones.currentDataZone()
    { host, port } = Datazones.getDataQueuesConfig(current)[dataZone].router.connect

    endpoint = "tcp://#{host}:#{port}"
    throw Err.ArgumentUnsupportedException("#{dataZone} does not exist") unless endpoint? 

    dataQueuesSenders[dataZone] = new Sender {router: endpoint}

  return dataQueuesSenders[dataZone]

getMediaQueuesSender = (dataZone) ->
  unless mediaQueuesSenders[dataZone]?
    current = Datazones.currentDataZone()
    { host, port } = Datazones.getMediaQueuesConfig(current)[dataZone].router.connect

    endpoint = "tcp://#{host}:#{port}"
    throw Err.ArgumentUnsupportedException("#{dataZone} does not exist") unless endpoint? 

    mediaQueuesSenders[dataZone] = new Sender {router: endpoint}

  return mediaQueuesSenders[dataZone]

module.exports.getDataQueuesSender = getDataQueuesSender
module.exports.getMediaQueuesSender = getMediaQueuesSender