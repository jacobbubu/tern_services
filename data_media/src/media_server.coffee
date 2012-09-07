process.title = 'Tern.Media'

ConfigGetter = require './config_getter'

ConfigGetter.init 'Media', (err, argv) ->
  console.error err.toString(), err.stack if err?

  console.log require('tern.logo').Media('0.1')

  ###
  # Register deleteMedia workers
  ###
  require './workers/delete_media'
  #require './workers/media_uri_write_back'

  ###
  # Start Media Server
  ###
  Express         = require 'express'
  Domain          = require 'domain'
  Log             = require 'tern.logger'

  # Middewares
  UserAuth        = require './mediafacets/user_auth'
  MediaUploader   = require './mediafacets/media_uploader'
  MediaDeleter    = require './mediafacets/media_deleter'
  RemovePoweredBy = require './mediafacets/x-powered-by'
  StaticMedia     = require './mediafacets/static_media'

  serverDomain = Domain.create()

  # Uncaught error trap
  serverDomain.on 'error', (err) ->
    Log.error "Uncaught error on Media Server: #{err.toString()}\r\n#{err.stack}"

  serverDomain.run ->
    app = Express.createServer()
    app.use RemovePoweredBy

    app.use (req, res, next) ->
      req._tern = {} unless req._tern?
      req._tern.media_zone = argv.data_zone
      next()

    # Does not exist in express 3.0
    #app.error (err, req, res, next) ->
    #  Log.error "Internal Error: #{err.toString()}, req: #{req.url}, header: #{JSON.stringify req.headers}"
    #  res.send 500

    host = if argv.host is '*' then null else argv.host
    app.listen argv.port, host, ->
      Log.notice "Media Server is listening on http://#{argv.host}:#{argv.port}"

    app.get '/', (req, res, next) ->
      res.type 'text/txt'
      res.send require('tern.logo').Media('0.1'), 200

    app.get '/1/memos/:media_id', UserAuth, StaticMedia()

    app.put '/1/memos/:media_id', UserAuth, MediaUploader

    app.del '/1/memos/:media_id', UserAuth, MediaDeleter
