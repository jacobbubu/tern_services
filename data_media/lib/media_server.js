// Generated by CoffeeScript 1.3.3
var ConfigGetter;

process.title = 'Tern.Media';

ConfigGetter = require('./config_getter');

ConfigGetter.init('Media', function(err, argv) {
  var Datazones, Domain, Express, Log, MediaDeleter, MediaUploader, RemovePoweredBy, StaticMedia, UserAuth, serverDomain;
  if (err != null) {
    console.error(err.toString(), err.stack);
  }
  console.log(require('tern.logo').Media('0.1'));
  Datazones = require('tern.data_zones');
  argv.data_zone = Datazones.currentDataZone();
  Express = require('express');
  Domain = require('domain');
  Log = require('tern.logger');
  UserAuth = require('./mediafacets/user_auth');
  MediaUploader = require('./mediafacets/media_uploader');
  MediaDeleter = require('./mediafacets/media_deleter');
  RemovePoweredBy = require('./mediafacets/x-powered-by');
  StaticMedia = require('./mediafacets/static_media');
  serverDomain = Domain.create();
  serverDomain.on('error', function(err) {
    return Log.error("Uncaught error on Media Server: " + (err.toString()) + "\r\n" + err.stack);
  });
  return serverDomain.run(function() {
    var app, host;
    app = Express.createServer();
    app.use(RemovePoweredBy);
    app.use(function(req, res, next) {
      if (req._tern == null) {
        req._tern = {};
      }
      req._tern.media_zone = argv.data_zone;
      return next();
    });
    host = argv.host === '*' ? null : argv.host;
    app.listen(argv.port, host, function() {
      return Log.notice("Media Server is listening on http://" + argv.host + ":" + argv.port);
    });
    app.get('/', function(req, res, next) {
      res.type('text/txt');
      return res.send(require('tern.logo')('Media. 0.1'), 200);
    });
    app.get('/1/memos/:media_id', UserAuth, StaticMedia());
    app.put('/1/memos/:media_id', UserAuth, MediaUploader);
    return app.del('/1/memos/:media_id', UserAuth, MediaDeleter);
  });
});
