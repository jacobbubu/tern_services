Datazones = require 'tern.data_zones'
ZMQSender = require('tern.zmq_helper').zmq_sender

senders = {}

getSender = (dataZone) ->
  unless senders[dataZone]?    
    {host, port} = Datazones.getZMQConnect dataZone
    endpoint = "tcp://#{host}:#{port}"
    console.log 'endpoint', endpoint
    throw Err.ArgumentUnsupportedException("#{dataZone} does not exist") unless endpoint? 

    senders[dataZone] = new ZMQSender(endpoint)

  return senders[dataZone]

module.exports.getSender = getSender