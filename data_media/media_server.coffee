Express         = require 'express'
Domain          = require 'domain'
Log             = require('ternlibs').logger

# Middewares
UserAuth        = require './mediafacets/user_auth'

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

  # Trap request error
  app.error (err, req, res, next) ->
    Log.error "Internal Error: #{err.toString()}, req: #{req.url}, header: #{JSON.stringify req.headers}"
    res.send 500

  app.listen argv.media_port, argv.media_host, ->
    Log.notice "Media Server is listening on http://#{argv.media_host}:#{argv.media_port}"

  app.get '/1/memos/:mid', UserAuth, (req, res, next) ->
    res.send(req._tern)
