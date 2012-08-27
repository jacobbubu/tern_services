// Generated by CoffeeScript 1.3.3
var Domain, Log, Perf, Utils, ZMQ, ZMQHandler, ZMQKey, ZMQResponder, ZMQStatusCodes;

Log = require('tern.logger');

Perf = require('tern.perf_counter');

Utils = require('tern.utils');

ZMQResponder = require('tern.zmq_helper').zmq_responder;

ZMQStatusCodes = require('tern.zmq_helper').zmq_status_codes;

ZMQKey = require('tern.zmq_helper').zmq_key;

ZMQ = require('zmq');

ZMQHandler = require('./zmqfacets/zmq_message_handler');

Domain = require('domain');

module.exports.start = function(argv) {
  var serverDomain;
  serverDomain = Domain.create();
  serverDomain.on('error', function(err) {
    return Log.error("Uncaught error on Auth. ZMQ Server: " + (err.toString()) + "\r\n" + err.stack);
  });
  return serverDomain.run(function() {
    var endpoint, serverSock;
    endpoint = "tcp://" + argv.host + ":" + argv.port;
    serverSock = ZMQ.socket('rep');
    serverSock.bind(endpoint, function() {
      return Log.notice("Auth. ZMQ Server is listening on " + endpoint + " ");
    });
    return serverSock.on('message', function(data) {
      var badMessage, internalError, message, messageObj;
      badMessage = function(e) {
        Log.error("ZMQ: " + (e.toString()) + "\r\n" + e.stack);
        return ZMQResponder.send(serverSock, ZMQStatusCodes.BadRequest, messageObj);
      };
      internalError = function(e) {
        Log.error("ZMQ: " + (e.toString()) + "\r\n" + e.stack + "\r\n" + message);
        return ZMQResponder(serverSock, ZMQStatusCodes.InternalServerError, messageObj);
      };
      try {
        message = Utils.decryptAndUnlzf(data, ZMQKey.key_iv);
        try {
          messageObj = JSON.parse(message);
          return ZMQHandler.processMessage(messageObj, function(err, res) {
            if (err != null) {
              return internalError(err);
            } else {
              try {
                return ZMQResponder.send(serverSock, messageObj, res);
              } catch (e) {
                return Log.error("ZMQ Error sending response:\r\n" + (e.toString()) + "\r\n" + e.stack + "\r\n" + message);
              }
            }
          });
        } catch (e) {
          return internalError(e, message);
        }
      } catch (e) {
        return badMessage(e);
      }
    });
  });
};