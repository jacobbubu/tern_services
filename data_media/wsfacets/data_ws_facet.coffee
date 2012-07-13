Log             = require('ternlibs').logger
Memos           = require('../models/memo_mod')
Tags            = require('../models/tag_mod')
Subscriptions   = require('../models/subscription_mod')
WSMessageHelper = require('ternlibs').ws_message_helper

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

module.exports.processMessage = (connection, message, next) ->

  dropError = (reasonCode, description, internalMessage) ->
    
    err = new Error(description ? internalMessage)
    err.reasonCode = reasonCode
    err.internalMessage = internalMessage if internalMessage?
    return err

  send = (req, res, cb) ->
    try
      res.method = req.method
      res.req_ts = req.req_ts
      response_message = 
        response: res
      
      responseString = JSON.stringify(response_message)
    
      WSMessageHelper.send connection, responseString, (err) ->
        cb err
    catch e
      cb e

  sendInternalError = (req, err, cb) ->
    res =       
      method: req.method
      req_ts: req.req_ts
      status: -10          #-10: Internal Error
    response_message = 
      response: res
    
    Log.error err.toString()

    WSMessageHelper.send connection, JSON.stringify(response_message), (e) ->
      cb e
    

  processResult = (err, req, res) ->
    if err?
      sendInternalError req, err, ->
        next err if next?
    else
      send req, res, ->
        next null, res if next?

  try
    textMessage = WSMessageHelper.parse message
    if Buffer.isBuffer(textMessage)
      throw dropError DropReason.CLOSE_REASON_PROTOCOL_ERROR
                    , "Unsupported message format."

    # Text Message then get the request
    try
      request = JSON.parse(textMessage).request 
    catch e 
      throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                    , "Bad message format"
                    , "Bad message format: \r\nuser_id: #{connection._tern.user_id}\r\nrequest: #{textMessage}"

    unless request
      throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                    , "Missing root property 'request'"
                    , "Missing root property 'request'. \r\nuser_id: #{connection._tern.user_id}\r\nrequest: #{textMessage}"

    request._tern = 
      user_id     : connection._tern.user_id
      scope       : connection._tern.scope
      device_id   : connection._tern.device_id
      contentLang : connection._tern.contentLang      

    unless request.req_ts? and request.method?
      throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                    , "Missing req_ts or method in request header"
                    , "Missing req_ts or method in request header. \r\nuser_id: #{connection._tern.user_id}\r\nrequest: #{textMessage}"

    unless request.data?
      throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                    , "Missing data in request"
                    , "Missing data in request. \r\nuser_id: #{connection._tern.user_id}\r\nrequest: #{textMessage}"

    methodName = request.method.toLowerCase()

    switch methodName
      when 'data.memo.upload'
        Memos.upload request, (err, res) ->
          processResult err, request, res

      when 'data.tag.upload'
        Tags.upload request, (err, res) ->
          processResult err, request, res

      when 'data.subscription.subscribe'
        Subscriptions.subscribe request, connection, (err, res) ->
          processResult err, request, res

      when 'data.subscription.unsubscribe'
        Subscriptions.unsubscribe request, connection, (err, res) ->
          processResult err, request, res

      when 'data.subscription.get'
        Subscriptions.get connection, (err, res) ->
          processResult err, request, res

      else
        throw dropError DropReason.CLOSE_REASON_INVALID_DATA
                      , "Unknown method in request header"
                      , "Missing method. \r\nclient_id: #{request.client_id}\r\nrequest: #{textMessage}"
      
  catch e
    next e