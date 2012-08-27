// Generated by CoffeeScript 1.3.3
var Assert, Fresh, HTTP, Log, MediaFile, ParseRange, SendMediaStream, Stream, etag, exports, send;

Log = require('tern.logger');

ParseRange = require('range-parser');

Fresh = require('fresh');

Stream = require('stream');

HTTP = require('http');

MediaFile = require('../models/media_file_mod');

Assert = require('assert');

send = function(req) {
  return new SendMediaStream(req);
};

etag = function(stats) {
  return "" + stats.currentLength + "-" + stats.mtime;
};

SendMediaStream = (function() {

  function SendMediaStream(req) {
    this.req = req;
    this.media_id = this.req._tern.media_id;
    Assert.ok(this.media_id != null);
    this.maxage(0);
  }

  SendMediaStream.prototype.pipe = function(res) {
    var self;
    this.res = res;
    self = this;
    MediaFile.stat(this.media_id, function(err, stats) {
      if (isNaN(stats.instanceLength)) {
        return self.error(404);
      }
      if (stats.instanceLength > stats.currentLength) {
        return self.error(404);
      }
      return self.send(stats);
    });
    return res;
  };

  SendMediaStream.prototype.send = function(stats) {
    var len, options, range, ranges, req, res;
    options = {};
    len = stats.instanceLength;
    req = this.req;
    res = this.res;
    range = req.headers.range;
    this.setHeader(stats);
    this.type(stats);
    if (range != null) {
      ranges = ParseRange(len, range);
      if (ranges === -1) {
        res.setHeader('Content-Range', 'bytes */' + stats.instanceLength);
        return this.error(416);
      }
      if (ranges !== -2) {
        options.start = ranges[0].start;
        options.end = ranges[0].end;
        len = options.end - options.start + 1;
        res.statusCode = 206;
        res.setHeader('Content-Range', 'bytes ', +options.start, +'-', +options.end, +'/', +stats.instanceLength);
      }
    }
    res.setHeader('Content-Length', len);
    if (req.method === 'HEAD') {
      return res.end();
    }
    return this.stream(options);
  };

  SendMediaStream.prototype.stream = function(options, next) {
    var req, res, self;
    self = this;
    res = this.res;
    req = this.req;
    return MediaFile.createReadStream(this.media_id, options, function(err, stream) {
      if ((err != null) && (next != null)) {
        return next(err);
      }
      Assert.ok(stream != null);
      self.emit('stream', stream);
      stream.pipe(res);
      req.on('close', stream.destroy.bind(stream));
      stream.on('error', function(err) {
        if (res._header) {
          Log.error(err.stack);
          req.destroy();
          return;
        }
        err.status = 500;
        return self.emit('error', err);
      });
      return stream.on('end', function() {
        return self.emit('end');
      });
    });
  };

  SendMediaStream.prototype.maxage = function(ms) {
    if (ms === Infinity) {
      ms = 60 * 60 * 24 * 365 * 1000;
    }
    this._maxage = ms;
    return this;
  };

  SendMediaStream.prototype.error = function(status, err) {
    var msg, res;
    res = this.res;
    msg = HTTP.STATUS_CODES[status];
    err = err != null ? err : new Error(msg);
    err.status = status;
    if (this.listeners('error').length > 0) {
      this.emit('error', err);
    }
    res.statusCode = err.status;
    return res.end(msg);
  };

  SendMediaStream.prototype.type = function(stats) {
    var res;
    res = this.res;
    if (res.getHeader('Content-Type') != null) {
      return;
    }
    return res.setHeader('Content-Type', stats.contentType);
  };

  SendMediaStream.prototype.setHeader = function(stats) {
    var res;
    res = this.res;
    res.setHeader('Accept-Ranges', 'bytes');
    if (res.getHeader('ETag') == null) {
      res.setHeader('ETag', etag(stats));
    }
    if (res.getHeader('Date') == null) {
      res.setHeader('Date', new Date().toUTCString());
    }
    if (res.getHeader('Cache-Control') == null) {
      res.setHeader('Cache-Control', 'public, max-age=' + (this._maxage / 1000));
    }
    if (res.getHeader('Last-Modified') == null) {
      return res.setHeader('Last-Modified', new Date(stats.mtime).toUTCString());
    }
  };

  SendMediaStream.prototype.isConditionalGET = function() {
    return this.req.headers['if-none-match'] || this.req.headers['if-modified-since'];
  };

  SendMediaStream.prototype.removeContentHeaderFields = function() {
    var field, res, _i, _len, _ref, _results;
    res = this.res;
    _ref = Object.keys(res._headers);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      field = _ref[_i];
      if (field.indexOf('content') === 0) {
        _results.push(res.removeHeader(field));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  SendMediaStream.prototype.notModified = function() {
    var res;
    res = this.res;
    this.removeContentHeaderFields();
    res.statusCode = 304;
    return res.end();
  };

  SendMediaStream.prototype.isCachable = function() {
    var res, _ref;
    res = this.res;
    return ((200 <= (_ref = res.statusCode) && _ref < 300)) || res.statusCode === 304;
  };

  SendMediaStream.prototype.isFresh = function() {
    return Fresh(this.req.headers, this.res._headers);
  };

  return SendMediaStream;

})();

SendMediaStream.prototype.__proto__ = Stream.prototype;

exports = module.exports = send;