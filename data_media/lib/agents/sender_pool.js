// Generated by CoffeeScript 1.3.3
var Datazones, ZMQSender, getSender, senders;

Datazones = require('tern.data_zones');

ZMQSender = require('tern.zmq_helper').zmq_sender;

senders = {};

getSender = function(dataZone) {
  var endpoint, host, port, _ref;
  if (senders[dataZone] == null) {
    _ref = Datazones.getZMQConnect(dataZone), host = _ref.host, port = _ref.port;
    endpoint = "tcp://" + host + ":" + port;
    console.log('endpoint', endpoint);
    if (endpoint == null) {
      throw Err.ArgumentUnsupportedException("" + dataZone + " does not exist");
    }
    senders[dataZone] = new ZMQSender(endpoint);
  }
  return senders[dataZone];
};

module.exports.getSender = getSender;
