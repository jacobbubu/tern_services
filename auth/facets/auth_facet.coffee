Log           = require('ternlibs').logger
Accounts      = require '../models/account_mod'

DropReason =
  CLOSE_REASON_NORMAL                 : 1000
  CLOSE_REASON_GOING_AWAY             : 1001
  CLOSE_REASON_PROTOCOL_ERROR         : 1002
  CLOSE_REASON_UNPROCESSABLE_INPUT    : 1003
  CLOSE_REASON_RESERVED               : 1004 # Reserved value.  Undefined meaning.
  CLOSE_REASON_NOT_PROVIDED           : 1005 # Not to be used on the wire
  CLOSE_REASON_ABNORMAL               : 1006 # Not to be used on the wire
  CLOSE_REASON_INVALID_DATA           : 1007
  CLOSE_REASON_POLICY_VIOLATION       : 1008
  CLOSE_REASON_MESSAGE_TOO_BIG        : 1009
  CLOSE_REASON_EXTENSION_REQUIRED     : 1010
  CLOSE_REASON_INTERNAL_SERVER_ERROR  : 1011
  CLOSE_REASON_TLS_HANDSHAKE_FAILED   : 1015 # Not to be used on the wire

module.exports.processMessage = (connection, message) ->

  dropError = (reasonCode, description, internalMessage) ->
    
    err = new Error(description ? internalMessage)
    err.reasonCode = reasonCode
    err.internalMessage = internalMessage if internalMessage?
    return err

  send = (req, res) ->
    res.method = req.method
    res.req_ts = req.req_ts
    response_message = 
      response: res
    connection.sendUTF JSON.stringify(response_message)


#- Function starts here

  if message.type is 'utf8'
    request = (JSON.parse message.utf8Data).request
    unless request
      throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                    , "Missing root property 'request'"
                    , "Missing root property 'request'. \r\nclient_id: #{connection.client_id}\r\nrequest: #{message.utf8Data}"

    request.client_id = connection.client_id

    unless request.req_ts? and request.method?
      throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                    , "Missing req_ts or method in request header"
                    , "Missing req_ts or method in request header. \r\nclient_id: #{request.client_id}\r\nrequest: #{JSON.stringify request}"

    unless request.data?
      throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                    , "Missing data in request"
                    , "Missing data in request. \r\nclient_id: #{request.client_id}\r\nrequest: #{JSON.stringify request}"

    methodName = request.method.toLowerCase()
    switch methodName
      when 'auth.signup'
        Accounts.signup request.client_id, request.data, (err, res) ->
          throw err if err? #Throw error is not a right way, we need to figue out a normal way to send err
          send request, res

      when 'auth.unique'
        Accounts.unique request.data.user_id, (err, res) ->          
          throw err if err?
          send request, res

      when 'auth.renewtokens'
        Accounts.renewTokens request.client_id, request.data, (err, res) ->
          throw err if err?
          send request, res

      when 'auth.refreshtoken'
        Accounts.refreshToken request.client_id, request.data.refresh_token, (err, res) ->
          throw err if err?
          send request, res

      else
        throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                      , "Unknown method in request header"
                      , "Missing method. \r\nclient_id: #{request.client_id}\r\nrequest: #{JSON.stringify request}"

  else
    throw dropError DropReason.CLOSE_REASON_PROTOCOL_ERROR
                  , "Binary message is unsupported."
