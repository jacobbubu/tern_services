Express         = require 'express'
Domain          = require 'domain'
Log             = require('ternlibs').logger

# Middewares
UserAuth        = require './mediafacets/user_auth'
MediaUploader   = require './mediafacets/media_uploader'
MediaDeleter    = require './mediafacets/media_deleter'
PoweredBy       = require './mediafacets/x-powered-by'
StaticMedia     = require './mediafacets/static_media'

console.log require('ternlibs').tern_logo('Media 0.1')

### 
#  Get Media Server Listening Port from Command Line
###
DefaultPorts = require('ternlibs').default_ports
argv = require('optimist')
      .default('media_port', DefaultPorts.MediaWeb.port)
      .default('media_host', DefaultPorts.MediaWeb.host)
      .argv

serverDomain = Domain.create()

# Uncaught error trap
serverDomain.on 'error', (err) ->
  Log.error 'Uncaught error on Media Server: ', err.toString()

serverDomain.run ->
  app = Express.createServer()
  app.use PoweredBy

  # Does not exist in express 3.0
  #app.error (err, req, res, next) ->
  #  Log.error "Internal Error: #{err.toString()}, req: #{req.url}, header: #{JSON.stringify req.headers}"
  #  res.send 500

  app.listen argv.media_port, argv.media_host, ->
    Log.notice "Media Server is listening on http://#{argv.media_host}:#{argv.media_port}"

  app.get '/1/memos/:media_id', UserAuth, StaticMedia()

  app.put '/1/memos/:media_id', UserAuth, MediaUploader

  app.del '/1/memos/:media_id', UserAuth, MediaDeleter