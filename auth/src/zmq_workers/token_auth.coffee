Log             = require('tern.logger')
Tokens          = require '../models/token_mod'
Responder       = require('tern.zmq_reqres').Responder
ZMQStatusCodes  = require('tern.zmq_helper').zmq_status_codes
PJ              = require 'prettyjson'

class TokenAuth
  run: (data, next) ->
    try
      return next "data must be an object." if typeof data isnt 'object'
      return next "data must be an object." unless data.access_token?

      accessToken = data.access_token

      Tokens.tokenAuth accessToken, (err, res) ->
        return next err if err?
        return next null, res
    catch err
      next err
      Log.error 'Request Error:\r\n' + PJ.render data + '\r\n' + err.toString() + '\r\n' + err.stack  

responder = null

module.exports.register = (options) ->
  unless responder?
    responder = new Responder options
    responder.registerWorker 'TokenAuth', TokenAuth
    Log.notice "ZMQ Worker 'TokenAuth' registered on #{options.dealer}"
