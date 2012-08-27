Datazones = require 'tern.data_zones'
ZMQSender = require('tern.zmq_helper').zmq_sender

senders = {}

getSender = (data_zone) ->
  unless senders[data_zone]?    
    {host, port} = Datazones.getZMQConnect data_zone
    endpoint = "tcp://#{host}:#{port}"
    console.log 'endpoint', endpoint
    throw Err.ArgumentUnsupportedException("#{data_zone} does not exist") unless endpoint? 

    senders[data_zone] = new ZMQSender(endpoint)

  return senders[data_zone]

module.exports.getSender = getSender