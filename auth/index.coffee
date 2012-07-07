
http            = require 'http'
locale          = require 'locale'
supportedLocale = new locale.Locales(["en"])

Log             = require('ternlibs').logger

WSServer  = (require 'websocket').server
Clients   = require './models/client_mod'
AuthFacet = require './facets/auth_facet'

process.title = 'Tern.Auth'

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
argv = require('optimist').default('ws_port', 8080).argv

httpServer.listen argv.ws_port, ->
  Log.notice "Auth. Server is listening on port #{argv.ws_port}"

InbandServer = require './inband-server'

wsServer.on 'request', (request) ->
  
  reject = (request, reasonCode, description, internalMessage) ->
    request.reject reasonCode, description

    #description = internalMessage ? description
    #Log.warning "Connection request rejected by the reason('#{reasonCode}: #{description}')."

  unless /^\/1\/websocket/i.test request.httpRequest.url
    return reject request, 404

  acceptLang = request.httpRequest.headers["accept-language"]
  if acceptLang?
    locales = new locale.Locales(acceptLang)
    contentLang = locales.best(supportedLocale).toString()

  authorization = request.httpRequest.headers.authorization
  return reject(request, 401, "Authorization required.") unless authorization?

  [authMethod, idLabel, client_id, secretLabel, client_secret] = authorization.match /[a-z0-9\-_]+/gi

  return reject(request, 401, "Unsupported authorization method '#{authMethod}'.") unless authMethod is 'Client'
  return reject(request, 401, "Credential required.") unless client_id? and client_secret?

  #request._tern.client_id = client_id

  Clients.authenticate client_id, client_secret, (err, res) ->
    if err?
      reject(request, 500, "Internal Error", err)
    else
      unless res
        reject(request, 401, 'Authentication failed.')
      else
        connection = request.accept 'auth', request.origin

        connection.client_id = client_id
        connection.contentLang = contentLang if contentLang?

        connection.on 'message', (message) ->
          try
            AuthFacet.processMessage connection, message
          catch e            
            if e.reasonCode?
              connection.drop e.reasonCode, e.toString()
              Log.error "Drop: #{e.reasonCode}, #{e.internalMessage}"
            else
              connection.drop 1011, "Internal error"
              Log.error "Drop: 1011, #{e.toString()}"

        connection.on 'close', (reasonCode, description) ->
          return
          #Log.info "Peer #{connection.remoteAddress} disconnected with the reason('#{reasonCode}: #{description}')."
