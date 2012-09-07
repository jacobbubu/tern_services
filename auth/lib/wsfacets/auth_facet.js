// Generated by CoffeeScript 1.3.3
var Accounts, DropReason, Log, PJ, WSMessageHelper;

Log = require('tern.logger');

WSMessageHelper = require('tern.ws_message_helper');

PJ = require('tern.prettyjson');

Accounts = require('../models/account_mod');

DropReason = {
  CLOSE_REASON_NORMAL: 1000,
  CLOSE_REASON_GOING_AWAY: 1001,
  CLOSE_REASON_PROTOCOL_ERROR: 1002,
  CLOSE_REASON_UNPROCESSABLE_INPUT: 1003,
  CLOSE_REASON_RESERVED: 1004,
  CLOSE_REASON_NOT_PROVIDED: 1005,
  CLOSE_REASON_ABNORMAL: 1006,
  CLOSE_REASON_INVALID_DATA: 1007,
  CLOSE_REASON_POLICY_VIOLATION: 1008,
  CLOSE_REASON_MESSAGE_TOO_BIG: 1009,
  CLOSE_REASON_EXTENSION_REQUIRED: 1010,
  CLOSE_REASON_INTERNAL_SERVER_ERROR: 1011,
  CLOSE_REASON_TLS_HANDSHAKE_FAILED: 1015
};

module.exports.processMessage = function(connection, message, next) {
  var dropError, methodName, request, send, textMessage;
  dropError = function(reasonCode, description, internalMessage) {
    var err;
    err = new Error(description != null ? description : internalMessage);
    err.reasonCode = reasonCode;
    if (internalMessage != null) {
      err.internalMessage = internalMessage;
    }
    return err;
  };
  send = function(req, res, cb) {
    var responseString, response_message;
    try {
      res.method = req.method;
      res.req_ts = req.req_ts;
      response_message = {
        response: res
      };
      responseString = JSON.stringify(response_message);
      return WSMessageHelper.send(connection, responseString, function(err) {
        return cb(err);
      });
    } catch (e) {
      return cb(e);
    }
  };
  try {
    textMessage = WSMessageHelper.parse(message);
    if (Buffer.isBuffer(textMessage)) {
      throw dropError(DropReason.CLOSE_REASON_PROTOCOL_ERROR, "Unsupported message format.");
    }
    try {
      request = JSON.parse(textMessage).request;
    } catch (e) {
      throw dropError(DropReason.CLOSE_REASON_INVALID_DATA, "Bad message format", "Bad message format: \r\nclient_id: " + connection._tern.client_id + "\r\n-\r\n" + (PJ.render(textMessage)));
    }
    if (!request) {
      throw dropError(DropReason.CLOSE_REASON_INVALID_DATA, "Missing root property 'request'", "Missing root property 'request'. \r\nclient_id: " + connection._tern.client_id + "\r\n-\r\n" + (PJ.render(textMessage)));
    }
    request.client_id = connection._tern.client_id;
    if (!((request.req_ts != null) && (request.method != null))) {
      throw dropError(DropReason.CLOSE_REASON_INVALID_DATA, "Missing req_ts or method in request header", "Missing req_ts or method in request header. \r\n-\r\n" + (PJ.render(request)));
    }
    if (request.data == null) {
      throw dropError(DropReason.CLOSE_REASON_INVALID_DATA, "Missing data in request", "Missing data in request.\r\n-\r\n" + (PJ.render(request)));
    }
    methodName = request.method.toLowerCase();
    switch (methodName) {
      case 'auth.signup':
        return Accounts.signup(request.client_id, request.data, function(err, res) {
          if (err != null) {
            return next(err);
          }
          return send(request, res, function(err) {
            if (err != null) {
              return next(err);
            }
            return next(null, res);
          });
        });
      case 'auth.unique':
        return Accounts.unique(request.data, function(err, res) {
          if (err != null) {
            return next(err);
          }
          return send(request, res, function(err) {
            if (err != null) {
              return next(err);
            }
            return next(null, res);
          });
        });
      case 'auth.renewtokens':
        return Accounts.renewTokens(request.client_id, request.data, function(err, res) {
          if (err != null) {
            return next(err);
          }
          return send(request, res, function(err) {
            if (err != null) {
              return next(err);
            }
            return next(null, res);
          });
        });
      case 'auth.refreshtoken':
        return Accounts.refreshToken(request.client_id, request.data.refresh_token, function(err, res) {
          if (err != null) {
            return next(err);
          }
          return send(request, res, function(err) {
            if (err != null) {
              return next(err);
            }
            return next(null, res);
          });
        });
      default:
        throw dropError(DropReason.CLOSE_REASON_INVALID_DATA, "Unknown method in request header", "Missing method. \r\n-\r\n" + (PJ.render(request)));
    }
  } catch (e) {
    return next(e);
  }
};
