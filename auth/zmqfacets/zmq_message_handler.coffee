Log             = require('ternlibs').logger
Tokens          = require '../models/token_mod'
Utils           = require('ternlibs').utils
ZMQStatusCodes  = require('ternlibs').zmq_status_codes
###
  Request example: 
  {
    req_ts  : 1337957267701,
    request: {
      method  : 'tokenAuth'
      data: {
        access_token: 'xxxxxxxxxx'
      }
    }
  }

  Response example: 
  {
    req_ts  : 1337957267701
    Response: {
      method  : 'tokenAuth'
      status  : 200
      data: {
        access_token: 'xxxxxxxxxx'
      }
    }
  }

  Error example: 
  {
    req_ts  : 1337957267701
    Response: {
      method  : 'tokenAuth'
      status  : 400
      error   : "'req_ts' in message required."
    }
  }

###
exports.processMessage = (message, next) ->
  
  dropError = (status, description) ->
    response =
      response:
        status: status 
        error: description

    next null, response if next?

  return dropError ZMQStatusCodes.BadRequest, "'req_ts' in message required." unless message.req_ts?
  return dropError ZMQStatusCodes.BadRequest, "'request' in message required." unless message.request?

  method = message.request.method
  return dropError "'request.method' in message required." unless method?

  method = method.trim()
  switch method.toLowerCase()
    when 'ping'
      response =
        response:
          status: ZMQStatusCodes.OK

      next null, response if next?

    when 'tokenauth'
      return dropError "'request.data.access_token' in message required." unless message.request.data?.access_token?

      accessToken = message.request.data.access_token

      Tokens.tokenAuth accessToken, (err, res) ->
        if err?
          next err
        else
          response =
            response: res

          next null, response if next?
    else
      response =
        response:
          status: ZMQStatusCodes.MethodNotAllowed

      next null, response if next?





