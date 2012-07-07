Log           = require('ternlibs').logger
Tokens        = require '../models/token_mod'
Utils         = require('ternlibs').utils
ZMQUtils      = require './zmq_utils'

###
  Example: 
  {
    req_ts  : 1337957267701,
    request: {
      method  : 'tokenAuth',
      data: {
        access_token: 'xxxxxxxxxx'
      }
    }
  }
###
exports.processMessage = (message, next) ->
  
  dropError = (description) ->
    err = new Error(description)
    next err if next?
    return err


  return dropError "'req_ts' in message required." unless message.req_ts?
  return dropError "'request' in message required." unless message.request?

  method = message.request.method
  return dropError "'request.method' in message required." unless method?

  method = method.trim()
  switch method.toLowerCase()
    when 'ping'
      response =
        req_ts: message.req_ts
        response:
          method: method
          status: 0

      next null, response if next?

    when 'tokenauth'
      return dropError "'request.data.access_token' in message required." unless message.request.data?.access_token?

      accessToken = message.request.data.access_token

      Tokens.tokenAuth accessToken, (err, res) ->
        if err?
          next err
        else
          response =
            req_ts: message.req_ts
            response: res

          response.response.method = method              
          next null, response if next?




