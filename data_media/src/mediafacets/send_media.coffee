Log         = require('tern.logger')
ParseRange  = require 'range-parser'
Fresh       = require('fresh')
Stream      = require 'stream'
HTTP        = require 'http'
MediaFile   = require '../models/media_file_mod'
Assert      = require 'assert'

send = (req) ->
  new SendMediaStream(req)

etag = (stats) ->
  "#{stats.currentLength}-#{stats.mtime}"

class SendMediaStream
  constructor: (@req) ->
    @media_id = @req._tern.media_id

    Assert.ok @media_id?

    @maxage(0)

  pipe: (res) ->    
    @res = res
    self = @

    MediaFile.stat @media_id, (err, stats) ->
      return self.error(404) if isNaN(stats.instanceLength)
      return self.error(404) if stats.instanceLength > stats.currentLength
      
      self.send stats

    return res

  send: (stats) ->
    options = {}
    len = stats.instanceLength
    req = @req
    res = @res
    range = req.headers.range

    @setHeader stats
    @type stats
    
    # conditional GET support
    #if @isConditionalGET() and @isCachable() and @isFresh()
    #  return @notModified()

    if range?
      ranges = ParseRange(len, range)

      # unsatisfiable
      if ranges is -1
        res.setHeader('Content-Range', 'bytes */' + stats.instanceLength);
        return @error(416)

      # valid (syntactically invalid ranges are treated as a regular response)
      if ranges isnt -2
        options.start = ranges[0].start
        options.end = ranges[0].end

        # Content-Range
        len = options.end - options.start + 1
        res.statusCode = 206
        res.setHeader('Content-Range', 'bytes '
          + options.start
          + '-'
          + options.end
          + '/'
          + stats.instanceLength)

    res.setHeader('Content-Length', len)
    return res.end() if req.method is 'HEAD'

    @stream options

  stream: (options, next) ->
    self = @
    res = @res
    req = @req

    # pipe
    MediaFile.createReadStream @media_id, options, (err, stream) ->
      return next err if err? and next?

      Assert.ok stream?

      self.emit 'stream', stream
      stream.pipe(res)

      # socket closed, done with the fd
      req.on 'close', stream.destroy.bind(stream)

      # error handling code-smell
      stream.on 'error', (err) ->
        # no hope in responding
        if (res._header)
          Log.error err.stack
          req.destroy()
          return

        # 500
        err.status = 500
        self.emit 'error', err

      # end
      stream.on 'end', ->
        self.emit 'end'

  maxage: (ms) ->
    ms = 60 * 60 * 24 * 365 * 1000 if ms is Infinity
    @_maxage = ms
    return @

  error: (status, err) ->
    res = @res
    msg = HTTP.STATUS_CODES[status]
    err = err ? new Error(msg)
    err.status = status
    @emit 'error', err if @listeners('error').length > 0
    res.statusCode = err.status
    res.end msg

  type: (stats) ->
    res = @res
    return if res.getHeader('Content-Type')?
    res.setHeader('Content-Type', stats.contentType)

  setHeader: (stats) ->
    res = @res
    res.setHeader 'Accept-Ranges', 'bytes'
    res.setHeader 'ETag', etag(stats) unless res.getHeader('ETag')?
    res.setHeader 'Date', new Date().toUTCString() unless res.getHeader('Date')?
    res.setHeader 'Cache-Control', 'public, max-age=' + (@_maxage / 1000) unless res.getHeader('Cache-Control')?
    res.setHeader 'Last-Modified', new Date(stats.mtime).toUTCString() unless res.getHeader('Last-Modified')?

  isConditionalGET: ->
    return @req.headers['if-none-match'] or @req.headers['if-modified-since']

  removeContentHeaderFields: ->
    res = @res
    for field in Object.keys(res._headers)
      if field.indexOf('content') is 0
        res.removeHeader(field)

  # Respond with 304 not modified.
  notModified: ->
    res = @res
    @removeContentHeaderFields()
    res.statusCode = 304
    res.end()

  isCachable: ->
    res = @res
    return (200 <= res.statusCode < 300) or res.statusCode is 304

  # Check if the cache is fresh.
  isFresh: ->
    return Fresh @req.headers, @res._headers


# Inherits from `Stream.prototype`
SendMediaStream.prototype.__proto__ = Stream.prototype

exports = module.exports = send