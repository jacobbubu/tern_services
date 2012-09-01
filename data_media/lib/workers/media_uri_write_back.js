// Generated by CoffeeScript 1.3.3
var Datazones, Log, MediaUriWriteback, Memo, PJ, Receiver, ZMQStatusCodes, current, dataQueues, dataZone, endpoint, host, port, receiver, value, _ref, _ref1;

Log = require('tern.logger');

Receiver = require('tern.queue').Receiver;

Datazones = require('tern.data_zones');

PJ = require('tern.prettyjson');

Memo = require('../models/memo_mod');

ZMQStatusCodes = require('tern.zmq_helper').zmq_status_codes;

MediaUriWriteback = (function() {

  function MediaUriWriteback() {}

  MediaUriWriteback.prototype.run = function(data, next) {
    return Memo.mediaUriWriteback(data, function(err, res) {
      var response, result, status;
      if ((next != null) && (err != null)) {
        return next(err);
      }
      try {
        result = res[0];
        status = result.status;
        switch (status) {
          case 1:
            response = {
              status: ZMQStatusCodes.BadRequest
            };
            break;
          case 0:
            response = {
              status: ZMQStatusCodes.OK
            };
            break;
          case -1:
            response = {
              status: ZMQStatusCodes.BadRequest
            };
            break;
          case -3:
            response = {
              status: ZMQStatusCodes.NotFound
            };
        }
        if (next != null) {
          next(null, response);
        }
      } catch (e) {
        return next(e);
      }
    });
  };

  return MediaUriWriteback;

})();

current = Datazones.currentDataZone();

_ref = Datazones.all();
for (dataZone in _ref) {
  value = _ref[dataZone];
  dataQueues = value.dataQueuesToOtherZones;
  if ((dataQueues != null ? dataQueues[current] : void 0) != null) {
    _ref1 = dataQueues != null ? dataQueues[current].dealer.connect : void 0, host = _ref1.host, port = _ref1.port;
    endpoint = "tcp://" + host + ":" + port;
    receiver = new Receiver({
      dealer: endpoint
    });
    receiver.registerWorker('MediaUriWriteback', MediaUriWriteback);
    Log.notice("Worker('MediaUriWriteback') from " + current + " to " + dataZone + " registered on " + endpoint);
  }
}
