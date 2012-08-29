// Generated by CoffeeScript 1.3.3
var ConfigGetter;

process.title = 'Tern.WebSocket';

ConfigGetter = require('./config_getter');

ConfigGetter.init('WebSocket', function(err, argv) {
  var App, DataWSFacet, Log, Timers, Token, WSServer, host, http, httpServer, locale, supportedLocale, wsServer;
  if (err != null) {
    console.error(err.toString(), err.stack);
  }
  console.log(require('tern.logo').WebSocket('0.1'));
  /*
    # Register mediaUriWriteback workers
  */

  require('./workers/media_uri_write_back');
  /*
    # Start Web Socket Server
  */

  App = require('express')();
  http = require('http');
  Log = require('tern.logger');
  locale = require('locale');
  supportedLocale = new locale.Locales(["en"]);
  WSServer = (require('websocket')).server;
  Token = require('./agents/token_agent');
  DataWSFacet = require('./wsfacets/data_ws_facet');
  Timers = require('timers');
  try {
    httpServer = http.createServer(App);
    App.get('/', function(req, res, next) {
      res.type('text/txt');
      return res.send(require('tern.logo')('Data. 0.1'), 200);
    });
    wsServer = new WSServer({
      httpServer: httpServer,
      autoAcceptConnections: false
    });
    host = argv.host === '*' ? null : argv.host;
    httpServer.listen(argv.port, host, function() {
      return Log.notice("Data WebSocket Server is listening on ws://" + argv.host + ":" + argv.port);
    });
    return wsServer.on('request', function(request) {
      var acceptLang, accessToken, authMethod, authorization, compressMethod, contentLang, device_id, locales, reject, remoteAddress, _ref, _ref1;
      remoteAddress = request.remoteAddress;
      reject = function(request, reasonCode, description, internalMessage) {
        request.reject(reasonCode, description);
        return Log.info("Peer " + remoteAddress + " rejected with the reason('" + reasonCode + ": " + description + "').");
      };
      if (!/^\/1\/websocket/i.test(request.httpRequest.url)) {
        return reject(request, 404, 'Not Found');
      }
      acceptLang = request.httpRequest.headers["accept-language"];
      if (acceptLang != null) {
        locales = new locale.Locales(acceptLang);
        contentLang = locales.best(supportedLocale).toString();
      }
      compressMethod = (_ref = request.httpRequest.headers['x-compress-method']) != null ? _ref : '';
      compressMethod = compressMethod.toLowerCase();
      if (compressMethod !== '' && compressMethod !== 'lzf') {
        return reject(request, 400, "Unsupported X_Compress_Method('" + compressMethod + "').");
      }
      device_id = request.httpRequest.headers['x-device-id'];
      if (device_id == null) {
        return reject(request, 400, "X-Device-ID required.");
      }
      device_id = device_id.trim().slice(0, 64);
      authorization = request.httpRequest.headers.authorization;
      if (authorization == null) {
        return reject(request, 401, "Authorization required.");
      }
      _ref1 = authorization.match(/[a-z0-9\-_]+/gi), authMethod = _ref1[0], accessToken = _ref1[1];
      if (authMethod !== 'Bearer') {
        return reject(request, 401, "Unsupported authorization method '" + authMethod + "'.");
      }
      if (accessToken == null) {
        return reject(request, 401, "Credential required.");
      }
      return Token.getInfo(accessToken, function(err, res) {
        var connection;
        if (err != null) {
          if ((err.name != null) && err.name === 'ResourceDoesNotExistException') {
            return reject(request, 401, 'Authentication failed.');
          } else {
            return reject(request, 500, "Internal Error", err);
          }
        } else {
          connection = request.accept('data', request.origin);
          Log.info("Connection count: " + wsServer.connections.length);
          connection._tern = {
            user_id: res.user_id,
            scope: res.scope,
            device_id: device_id,
            contentLang: contentLang != null ? contentLang : void 0,
            ws_server: wsServer,
            compressMethod: compressMethod,
            data_zone: argv.data_zone
          };
          connection.on('message', function(message) {
            return DataWSFacet.processMessage(connection, message, function(err, res) {
              if (err != null) {
                if (err.reasonCode != null) {
                  connection.drop(err.reasonCode, err.toString());
                  return Log.error("Drop: " + err.reasonCode + ", " + err.internalMessage);
                } else {
                  connection.drop(1011, "Internal error");
                  return Log.error("Drop: 1011, " + (err.toString()));
                }
              }
            });
          });
          return connection.on('close', function(reasonCode, description) {
            if (connection._tern.timeoutId != null) {
              Timers.clearTimeout(connection._tern.timeoutId);
              return connection._tern.timeoutId = null;
            }
          });
        }
      });
    });
  } catch (err) {
    return Log.error("Uncaught error on WebSocket Server: " + (err.toString()) + "\r\n" + err.stack);
  }
});
