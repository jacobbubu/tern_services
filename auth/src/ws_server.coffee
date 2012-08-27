App             = require('express')()
Log             = require('tern.logger')
Perf            = require('tern.perf_counter')
Utils           = require('tern.utils')

http            = require 'http'
locale          = require 'locale'
supportedLocale = new locale.Locales(["en"])

WSServer        = (require 'websocket').server
Clients         = require './models/client_mod'
AuthFacet       = require './wsfacets/auth_facet'

Domain          = require 'domain'

module.exports.start = (argv) ->
  serverDomain = Domain.create()

  # Uncaught error trap
  serverDomain.on 'error', (err) ->
    Log.error 'Uncaught error on Auth. WS Server: ', err.toString()

  serverDomain.run ->
    httpServer = http.createServer(App)

    App.get '/', (req, res, next) ->
      res.type 'text/txt'
      res.send require('tern.logo')('Auth. 0.1'), 200

    wsServer = new WSServer {
        httpServer: httpServer,
        autoAcceptConnections: false
      }

    host = if argv.host is '*' then null else argv.host

    httpServer.listen argv.port, host, ->
      Log.notice "Auth. Web Socket Server is listening on ws://#{argv.host}:#{argv.port}"

    wsServer.on 'request', (request) ->

      reject = (request, reasonCode, description, internalMessage) ->
        try
          request.reject reasonCode, description
        catch err
          Log.warning 'Error sending reject:', err.toString()

        description = internalMessage ? description
        Log.warning "Connection request rejected by the reason('#{reasonCode}: #{description}')."

      unless /^\/1\/websocket/i.test request.httpRequest.url
        return reject request, 404

      acceptLang = request.httpRequest.headers["accept-language"]
      if acceptLang?
        locales = new locale.Locales(acceptLang)
        contentLang = locales.best(supportedLocale).toString()

      #compress_method parser
      compressMethod = request.httpRequest.headers['x-compress-method'] ? ''
      compressMethod = compressMethod.toLowerCase()
      if compressMethod isnt '' and compressMethod isnt 'lzf'
        return reject(request, 400, "Unsupported X_Compress_Method('#{compressMethod}').")

      authorization = request.httpRequest.headers.authorization
      
      return reject(request, 401, "Authorization required.") unless authorization?

      [authMethod, idLabel, client_id, secretLabel, client_secret] = authorization.match /[a-z0-9\-_]+/gi

      return reject(request, 401, "Unsupported authorization method '#{authMethod}'.") unless authMethod is 'Client'
      return reject(request, 401, "Credential required.") unless client_id? and client_secret?

      #request._tern.client_id = client_id

      Clients.authenticate client_id, client_secret, (err, res) ->
        return reject(request, 500, 'Internal Error', err) if err?

        unless res
          reject(request, 401, 'Authentication failed.')
        else
          connection = request.accept 'auth', request.origin

          connection._tern =
            client_id       : client_id
            contentLang     : contentLang if contentLang?
            compressMethod  : compressMethod

          # Message is coming
          connection.on 'message', (message) ->
            AuthFacet.processMessage connection, message, (err) ->
              if err?
                try
                  if err.reasonCode?
                    connection.drop err.reasonCode, err.toString()
                    Log.error "Drop: #{err.reasonCode}, #{err.internalMessage}"
                  else
                    connection.drop 1011, "Internal error"
                    Log.error "Drop: 1011, #{err.toString()}"
                catch e
                  Log.error "Error sending:", e.toString()

          connection.on 'close', (reasonCode, description) ->
            return
            #Log.info "Peer #{connection.remoteAddress} disconnected with the reason('#{reasonCode}: #{description}')."
