Log        = require('ternlibs').logger
Utils      = require('ternlibs').utils
MediaType  = require('ternlibs').media_type
Err        = require './media_error'
Assert     = require('assert')

MediaFile  = require '../models/media_file_mod'

MediaIdPattern  = /^([^\s]{1,24}):[+-]?(\d{1,18})$/
LengthPattern   = /^\d{1,18}$/

MaxInstanceSize = 150 * 1024 * 1024 #150M
MaxEntitySize   = 4 * 1024 * 1024 #4M

headersParse = (req, res) ->

  requestObj = null

  contentLength = req.headers['content-length']
  unless contentLength?
    Err.sendError res, Err.CODES.CONTENT_LENGTH_REQUIRED unless contentLength?
    return requestObj

  contentLength = parseInt(contentLength, 10)
  if isNaN(contentLength) or contentLength < 0 or contentLength > MaxEntitySize
    Err.sendError res, Err.CODES.CONTENT_LENGTH_IS_OOR, 0, Utils.byteSizePresent(MaxEntitySize)
    return requestObj

  contentType = req.headers['content-type']
  unless contentType?
    Err.sendError res, Err.CODES.CONTENT_TYPE_REQUIRED
    return requestObj

  contentType = contentType.toLowerCase()
  unless MediaType.isSupported(contentType)
    Err.sendError res, Err.CODES.CONTENT_TYPE_UNSUPPORTED
    return requestObj

  rangeValue = req.headers['content-range']
  unless rangeValue?
    Err.sendError res, Err.CODES.CONTENT_RANGE_REQUIRED
    return requestObj

  [unit, byteRangeResp, instanceLength] = rangeValue.match /[a-z0-9\-_\*]+/gi 

  if unit.toLowerCase() isnt 'bytes'
    Err.sendError res, Err.CODES.CONTENT_RANGE_UNSUPPORTED_UNIT
    return requestObj

  # instanceLength MUST BE number
  unless /^\d+$/.test(instanceLength)
    Err.sendError res, Err.CODES.CONTENT_RANGE_INVALID_INSTANCE_LENGTH
    return requestObj

  instanceLength = parseInt(instanceLength, 10)
  if isNaN(instanceLength)
    Log.error "parsesInt error: instance length of content-range ('#{instanceLength}') ."
    Err.sendError res, Err.CODES.CONTENT_RANGE_INVALID_INSTANCE_LENGTH
    return requestObj
  else
    unless 0 < instanceLength < MaxInstanceSize 
      Err.sendError res, Err.CODES.CONTENT_RANGE_INSTANCE_LENGTH_IS_OOR, 0, Utils.byteSizePresent(MaxInstanceSize)
      return requestObj

  [firstBytePos, lastBytePos] = byteRangeResp.split '-'

  firstBytePos = if isNaN(parseInt(firstBytePos, 10)) then 0 else parseInt(firstBytePos, 10)
  lastBytePos  = if isNaN(parseInt(lastBytePos , 10)) then 0 else parseInt(lastBytePos , 10)

  if contentLength > instanceLength
    Err.sendError res, Err.CODES.CONTENT_LENGTH_IS_GREATER_THAN_INSTANCE_LENGTH
    return requestObj

  instanceMD5 = req.headers['x-instance-md5']
  if instanceMD5?
    try
      instanceMD5 = Utils.base64ToHex(instanceMD5)
    catch e
      Err.sendError res, Err.CODES.BAD_MD5
      return requestObj

  requestObj =
    instanceLength : instanceLength
    instanceMD5    : instanceMD5
    firstBytePos   : firstBytePos
    lastBytePos    : lastBytePos
    contentLength  : contentLength
    contentType    : contentType


send308Range = (res, length) ->
  lastPos = if length <= 0 then 0 else length - 1
  res.header('Range', "0-#{lastPos}")
  res.send 308

send200ok = (res) ->
  res.header('Content-Length', 0)
  res.statusCode = 200
  res.end()

###
  Media upload middleware
###
mediaUpload = (req, res, next) ->
  Assert.equal req.method, 'PUT'
  Assert.ok    req._tern
  Assert.ok    req._tern.user_id
  Assert.ok    req._tern.media_id

  req.pause()

  requestParams = headersParse req, res
  if requestParams?

    mediaStore  = null
    uploadResult = null

    fileInfo = requestParams
    fileInfo.media_id = req._tern.media_id

    invalidParams = fileInfo.firstBytePos is fileInfo.lastBytePos
    invalidParams = invalidParams || fileInfo.contentLength is 0
    invalidParams = invalidParams || fileInfo.lastBytePos - fileInfo.firstBytePos + 1 isnt fileInfo.contentLength

    if invalidParams
      MediaFile.stat req._tern.media_id, (err, stats) ->
        return next(err) if err?

        #uploadResult = {}
        #uploadResult.length = stats.currentLength
        return send308Range res, stats.currentLength
    else
      # Open File
      MediaFile.startUpload fileInfo, (err, gridStore) ->
        return next err if err?
          
        mediaStore = gridStore          

        # Already completed
        if mediaStore.position is fileInfo.instanceLength
          MediaFile.closeUpload fileInfo, mediaStore, (err, result) ->
            return next err if err?
            uploadResult = result
            send200ok res
          return

        # 308, if range wrong
        if fileInfo.firstBytePos isnt mediaStore.position or fileInfo.lastBytePos + 1 > fileInfo.instanceLength

          MediaFile.closeUpload fileInfo, mediaStore, (err, result) ->
            return next err if err?
            uploadResult = result
            return send308Range res, mediaStore.position
          return

        chunkUpload = (chunk, next) ->
          
          #console.log 'Before mediaStore.position:', mediaStore.position
          if mediaStore.position >= fileInfo.instanceLength
            # Already completed, return 200

            MediaFile.closeUpload fileInfo, mediaStore, (err, result) ->
              return next err, result
          
          MediaFile.rangeUpload fileInfo, mediaStore, chunk, (err, result) ->
            #console.log 'After mediaStore.position:', mediaStore.position, result              
            return next err, result

        req.on 'data', (chunk) ->
          req.pause()

          chunkUpload chunk, (err, result) ->
            return next err if err?
            uploadResult = result
            req.resume()
              
        req.on 'end', () ->
          unless uploadResult?
            MediaFile.closeUpload fileInfo, mediaStore, (err, result) ->
              return next err if err?
              send308Range res, result.length
          else
            if fileInfo.instanceMD5?              
              if fileInfo.instanceMD5 is uploadResult.md5
                send200ok res
              else
                Err.sendError res, Err.CODES.UNMATCHED_MD5
            else
              send200ok res

        req.on 'close', () ->
          return

        req.resume()
  else
    return


module.exports = mediaUpload