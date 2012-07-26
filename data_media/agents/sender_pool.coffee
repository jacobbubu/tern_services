DataZones     = require('ternlibs').consts.data_zones
ZMQSender     = require('ternlibs').zmq_sender

senders = {}

getSender = (data_zone) ->
  unless senders[data_zone]?
    console.log data_zone
    endpoint = DataZones[data_zone].zmq
    throw Err.ArgumentUnsupportedException("#{data_zone} does not exist") unless endpoint? 

    senders[data_zone] = new ZMQSender(endpoint)

  return senders[data_zone]

module.exports.getSender = getSender