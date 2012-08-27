Log             = require('tern.logger')
Utils           = require('tern.utils')
ZMQStatusCodes  = require('tern.zmq_helper').zmq_status_codes
Memo            = require '../models/memo_mod'
MediaFile       = require('../models/media_file_mod')

exports.processMessage = (message, next) ->
  
  dropError = (status, description) ->
    response =
      response:
        status: status 
        error: description

    next null, response if next?

  return dropError ZMQStatusCodes.BadRequest, "'req_ts' required." unless message.req_ts?
  return dropError ZMQStatusCodes.BadRequest, "'request' required." unless message.request?

  method = message.request.method
  return dropError "'request.method' in message required." unless method?

  method = method.trim()
  switch method.toLowerCase()
    when 'ping'
      response =
        response:
          status: ZMQStatusCodes.OK

      next null, response if next?

    when 'mediauriwriteback'
      changedMemo = message.request.data
      return dropError ZMQStatusCodes.BadRequest, "'request.data' required." unless changedMemo?

      return dropError ZMQStatusCodes.BadRequest, "'request.data.mid' in message required."            unless changedMemo.mid?
      return dropError ZMQStatusCodes.BadRequest, "'request.data.user_id' in message required."        unless changedMemo.user_id?
      return dropError ZMQStatusCodes.BadRequest, "'request.data.device_id' in message required."      unless changedMemo.device_id?
      return dropError ZMQStatusCodes.BadRequest, "'request.data.updated_at' in message required."     unless changedMemo.updated_at?
      return dropError ZMQStatusCodes.BadRequest, "'request.data.media_meta' in message required."     unless changedMemo.media_meta?
      return dropError ZMQStatusCodes.BadRequest, "'request.data.media_meta.uri' in message required." unless changedMemo.media_meta.uri?

      Memo.mediaUriWriteback message.request.data, (err, res) ->
        return next err if next? and err?

        try        
          result = res[0]

          #  0: Success
          #  1: Has a new version
          # -1: bad argument
          # -3: Not Found
          
          status = result.status
          switch status
            when 1
              response =
                response:
                  status: ZMQStatusCodes.BadRequest
            when 0
              response =
                response:
                  status: ZMQStatusCodes.OK
            when -1
              response =
                response:
                  status: ZMQStatusCodes.BadRequest
            when -3
              response =
                response:
                  status: ZMQStatusCodes.NotFound

          next null, response if next?
          return

        catch e 
          return next e

    when 'deletemedia'
      media_id = message.request.data.media_id

      MediaFile.unlink media_id, (err, numberOfRemovedMedia) ->
        return next err if next? and err?

        if numberOfRemovedMedia > 0
          response =
            response:
              status: ZMQStatusCodes.OK
        else
          response =
            response:
              status: ZMQStatusCodes.NotFound

        next null, response if next?

    # Unknown method
    else
      response =
        response:
          status: ZMQStatusCodes.MethodNotAllowed

      next null, response if next?

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