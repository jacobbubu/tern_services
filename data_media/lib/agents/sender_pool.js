// Generated by CoffeeScript 1.3.3
var Datazones, Sender, dataQueuesSenders, getDataQueuesSender, getMediaQueuesSender, mediaQueuesSenders;

Datazones = require('tern.data_zones');

Sender = require('tern.queue').Sender;

dataQueuesSenders = {};

mediaQueuesSenders = {};

getDataQueuesSender = function(dataZone) {
  var current, endpoint, host, port, _ref;
  if (dataQueuesSenders[dataZone] == null) {
    current = Datazones.currentDataZone();
    _ref = Datazones.getDataQueuesConfig(current)[dataZone].router.connect, host = _ref.host, port = _ref.port;
    endpoint = "tcp://" + host + ":" + port;
    if (endpoint == null) {
      throw Err.ArgumentUnsupportedException("" + dataZone + " does not exist");
    }
    dataQueuesSenders[dataZone] = new Sender({
      router: endpoint
    });
  }
  return dataQueuesSenders[dataZone];
};

getMediaQueuesSender = function(dataZone) {
  var current, endpoint, host, port, _ref;
  if (mediaQueuesSenders[dataZone] == null) {
    current = Datazones.currentDataZone();
    _ref = Datazones.getMediaQueuesConfig(current)[dataZone].router.connect, host = _ref.host, port = _ref.port;
    endpoint = "tcp://" + host + ":" + port;
    if (endpoint == null) {
      throw Err.ArgumentUnsupportedException("" + dataZone + " does not exist");
    }
    mediaQueuesSenders[dataZone] = new Sender({
      router: endpoint
    });
  }
  return mediaQueuesSenders[dataZone];
};

module.exports.getDataQueuesSender = getDataQueuesSender;

module.exports.getMediaQueuesSender = getMediaQueuesSender;
