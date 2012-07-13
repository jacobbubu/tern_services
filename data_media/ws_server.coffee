http            = require 'http'
Log             = require('ternlibs').logger

locale          = require 'locale'
supportedLocale = new locale.Locales(["en"])

WSServer        = (require 'websocket').server

Token           = require './models/token_mod'
DataWSFacet     = require './wsfacets/data_ws_facet'

Timers          = require('timers')

httpServer = http.createServer (request, response) ->
  Log.info (new Date()) + ' Received request for ' + request.url
  response.writeHead(404)
  response.end()

wsServer = new WSServer {
    httpServer: httpServer,
    autoAcceptConnections: false
  }

###
#  Get WebSocket Server Listening Port from Command Line
###
DefaultPorts = require('ternlibs').default_ports
argv = require('optimist')
      .default('ws_port', DefaultPorts.DataWS.port)
      .default('ws_host', DefaultPorts.DataWS.host)
      .argv

httpServer.listen argv.ws_port, argv.ws_host, ->
  Log.notice "Data WebSocket Server is listening on ws://#{argv.ws_host}:#{argv.ws_port}"

wsServer.on 'request', (request) ->
  
  reject = (request, reasonCode, description, internalMessage) ->    
    request.reject reasonCode, description
    Log.info "Peer #{request.remoteAddress} rejected with the reason('#{reasonCode}: #{description}')."

  # endpoint must be 'host/websocket'
  unless /^\/1\/websocket/i.test request.httpRequest.url
    return reject request, 404

  #Accept-Language parser
  acceptLang = request.httpRequest.headers["accept-language"]
  if acceptLang?
    locales = new locale.Locales(acceptLang)
    contentLang = locales.best(supportedLocale).toString()

  #compress_method parser
  compressMethod = request.httpRequest.headers['x-compress-method'] ? ''
  compressMethod = compressMethod.toLowerCase()
  if compressMethod isnt '' and compressMethod isnt 'lzf'
    return reject(request, 400, "Unsupported X_Compress_Method('#{compressMethod}').")

  #X_Device_ID parser
  device_id = request.httpRequest.headers['x-device-id']
  return reject(request, 400, "X-Device-ID required.") unless device_id?

  device_id = device_id.trim().slice(0, 64)

  authorization = request.httpRequest.headers.authorization
  return reject(request, 401, "Authorization required.") unless authorization?

  [authMethod, accessToken] = authorization.match /[a-z0-9\-_]+/gi

  return reject(request, 401, "Unsupported authorization method '#{authMethod }'.") unless authMethod is 'Bearer'
  return reject(request, 401, "Credential required.") unless accessToken?

  Token.getInfo accessToken, (err, res) ->
    if err?
      if err.name? and err.name is 'ResourceDoesNotExistException'
        reject(request, 401, 'Authentication failed.')
      else
        reject(request, 500, "Internal Error", err)
    else
      connection = request.accept 'data', request.origin

      Log.info "Connection count: #{wsServer.connections.length}"

      connection._tern =
        user_id         : res.user_id
        scope           : res.scope
        device_id       : device_id
        contentLang     : contentLang if contentLang?
        ws_server       : wsServer
        compressMethod  : compressMethod

      connection.on 'message', (message) ->

        DataWSFacet.processMessage connection, message, (err, res) ->
          if err?
            if err.reasonCode?
              connection.drop err.reasonCode, err.toString()
              Log.error "Drop: #{err.reasonCode}, #{err.internalMessage}"
            else
              connection.drop 1011, "Internal error"
              Log.error "Drop: 1011, #{err.toString()}"

      connection.on 'close', (reasonCode, description) ->
        if connection._tern.timeoutId?
          Timers.clearTimeout connection._tern.timeoutId 
          connection._tern.timeoutId = null