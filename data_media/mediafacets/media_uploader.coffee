Log        = require('ternlibs').logger
Utils      = require('ternlibs').utils
MediaType  = require('ternlibs').media_type
Err        = require './media_error'
Assert     = require('assert')

MediaFile  = require '../models/media_file_mod'

MediaIdPattern  = /^([^\s]{1,24}):[+-]?(\d{1,18})$/
LengthPattern   = /^\d{1,18}$/

MaxInstanceSize = 150 * 1024 * 1024 #150M
MaxEntitySize   = 1 * 1024 * 1024 #2M

###
  Content-Range = "Content-Range" ":" content-range-spec

  content-range-spec      = byte-content-range-spec
  byte-content-range-spec = bytes-unit SP
                            byte-range-resp-spec "/"
                            ( instance-length | "*" )

  byte-range-resp-spec = (first-byte-pos "-" last-byte-pos)
                                 | "*"
  instance-length           = 1*DIGIT
###
headersParse = (req, res) ->

  contentRangeObj = null

  contentLength = req.headers['content-length']
  unless contentLength?
    Err.sendError res, Err.CODES.CONTENT_LENGTH_REQUIRED unless contentLength?
    return contentRangeObj

  contentLength = parseInt(contentLength, 10)
  if isNaN(contentLength) or contentLength < 0 or contentLength > MaxEntitySize
    Err.sendError res, Err.CODES.CONTENT_LENGTH_IS_OOR, 0, Utils.byteSizePresent(MaxEntitySize)
    return contentRangeObj

  contentType = req.headers['content-type']
  unless contentType?
    Err.sendError res, Err.CODES.CONTENT_TYPE_REQUIRED
    return contentRangeObj

  contentType = contentType.toLowerCase()
  unless MediaType.isSupported(contentType)
    Err.sendError res, Err.CODES.CONTENT_TYPE_UNSUPPORTED
    return contentRangeObj

  rangeValue = req.headers['content-range']
  unless rangeValue?
    Err.sendError res, Err.CODES.CONTENT_RANGE_REQUIRED
    return contentRangeObj

  [unit, byteRangeResp, instanceLength] = rangeValue.match /[a-z0-9\-_\*]+/gi 

  if unit.toLowerCase() isnt 'bytes'
    Err.sendError res, Err.CODES.CONTENT_RANGE_UNSUPPORTED_UNIT
    return contentRangeObj

  # instanceLength MUST BE number
  unless /^\d+$/.test(instanceLength)
    Err.sendError res, Err.CODES.CONTENT_RANGE_INVALID_INSTANCE_LENGTH
    return contentRangeObj

  instanceLength = parseInt(instanceLength, 10)
  if isNaN(instanceLength)
    Log.error "parsesInt error: instance length of content-range ('#{instanceLength}') ."
    Err.sendError res, Err.CODES.CONTENT_RANGE_INVALID_INSTANCE_LENGTH
    return contentRangeObj
  else
    unless 0 < instanceLength < MaxInstanceSize 
      Err.sendError res, Err.CODES.CONTENT_RANGE_INSTANCE_LENGTH_IS_OOR, 0, Utils.byteSizePresent(MaxInstanceSize)
      return contentRangeObj

  [firstBytePos, lastBytePos] = byteRangeResp.split '-'

  firstBytePos = if isNaN(parseInt(firstBytePos, 10)) then 0 else parseInt(firstBytePos, 10)
  lastBytePos  = if isNaN(parseInt(lastBytePos , 10)) then 0 else parseInt(lastBytePos , 10)

  if contentLength > instanceLength
    Err.sendError res, Err.CODES.CONTENT_LENGTH_IS_GREATER_THAN_INSTANCE_LENGTH
    return contentRangeObj

  contentRangeObj =
    instanceLength : instanceLength
    firstBytePos   : firstBytePos
    lastBytePos    : lastBytePos
    contentLength  : contentLength
    contentType    : contentType

###
  Media upload middleware
###
mediaUpload = (req, res, next) ->
  Assert.equal req.method, 'PUT'
  Assert.ok    req._tern
  Assert.ok    req._tern.user_id
  Assert.ok    req._tern.media_id

  contentRangeObj = headersParse req, res
  if contentRangeObj?
    MediaFile.stat req._tern.media_id, (err, stats) ->
      return next err if err?
      
      if stats?
        res.send stats, 200
      else
        res.send {}, 200
    #Get grid file info.
    
  else
    return


module.exports = mediaUpload
