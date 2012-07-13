###
# Password Hash Module
###
PasswordHash    = require './password-hash'

###
# mkdir /p module
###
exports.mkdirp  = require './mkdirp'

Zlib            = require 'zlib'
Crypto          = require 'crypto'
Lzf             = require './lzf'
ZMQKey          = require '../consts/zmq_key'

###
# Array Helpers
###
unless Array::unique
  Array::unique = ->
    output = {}
    output[@[key]] = @[key] for key in [0...@length]
    value for key, value of output

unless Array::merge
  Array::merge = (other) -> Array::push.apply @, other

unless Array::filter
  Array::filter = (callback) ->
    element for element in this when callback(element)

###
# Array Helpers
###

# '1234'.shuffle() = '4321'
unless String::reverse
  String::reverse = -> 
    (@.split '').reverse().join ''

# '12345'.shuffle() = '35214'
unless String::shuffle
  String::shuffle = -> 
    ( (@.split '').sort -> 0.5 - Math.random() ).join ''

PATH_CHAR = '/'
TAG_SPLIT_CHAR = ':'

exports.pathJoin = (args...) ->
  args.join PATH_CHAR

###
# Get type description in coffeescript way 
###
exports.type = (obj) ->
  if obj == undefined or obj == null
    return String obj

  classToType = new Object
  for name in "Boolean Number String Function Array Date RegExp".split(" ")
    classToType["[object " + name + "]"] = name.toLowerCase()

  myClass = Object.prototype.toString.call obj
  if myClass of classToType
    return classToType[myClass]

  return "object"

###
# Clone object or array
###
exports.clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj
  
  switch exports.type(obj)
    when 'date'
      return new Date(obj.getTime())
    when 'regexp'
      flags = '' + (obj.global ? 'g' : '') + (obj.ignoreCase ? 'i' : '') + (obj.multiline ? 'm' : '') + (obj.sticky ? 'y' : '')
      return new RegExp(obj.source, flags)        

  newInstance = new obj.constructor()
  for own key of obj
    newInstance[key] = exports.clone obj[key]
  return newInstance

###
# Snapshot a config object
###
exports.configSnapshot = (configNode) ->
  result = {}

  for own k, v of configNode
    if not v? or typeof v isnt 'object'
      result[k] = v
      continue
    
    switch exports.type(v)
      when 'date'
        result[k] = Date(v.getTime())
        continue
      when 'regexp'
        flags = '' + (v.global ? 'g' : '') + (v.ignoreCase ? 'i' : '') + (v.multiline ? 'm' : '') + (v.sticky ? 'y' : '')
        result[k] = RegExp(v.source, flags)
        continue

    result[k] = exports.configSnapshot v

  return result

###
# Passeord Hash
###
exports.passwordHash = (password) ->
  return PasswordHash.generate(password)
  
exports.verifyPassword = (password, hashedPassword) ->
  return PasswordHash.verify(password, hashedPassword)

hexToBinaryString = (value) ->
  return new Buffer(value, "hex").toString("binary")

###
# compress and encrypt
# params
#   data: A string
#   key_iv: A object includes key and iv ({key: 'xxx', iv: 'xxx'}).
# return
#   A buffer object
###
exports.compressAndEncrypt = (data, key_iv, next) ->

  Zlib.deflate data, (err, buffer) ->
    return next err if err?
    
    cipher = Crypto.createCipheriv("aes-128-cbc", hexToBinaryString(key_iv.key), hexToBinaryString(key_iv.iv))
    result = cipher.update(buffer, 'binary', 'binary')
    result += cipher.final('binary')
    res = new Buffer(result, 'binary')

    next null, res

###
# encrypt a string
# params
#   data: A string
#   key_iv: A object includes key and iv ({key: 'xxx', iv: 'xxx'}).
# return
#   A buffer object
###
exports.encrypt = (data, key_iv) ->
  cipher = Crypto.createCipheriv("aes-128-cbc", hexToBinaryString(key_iv.key), hexToBinaryString(key_iv.iv))
  result = cipher.update(data, 'utf8', 'binary')
  result += cipher.final('binary')
  return new Buffer(result, 'binary')

###
#  decrypt and unzip
# params
#   buffer: A buffer object
#   key_iv: A object includes key and iv ({key: 'xxx', iv: 'xxx'}).
# return
#   A string
###
exports.decryptAndUncompress = (buffer, key_iv, next) ->

  data = buffer.toString('binary')

  decipher = Crypto.createDecipheriv("aes-128-cbc", hexToBinaryString(key_iv.key), hexToBinaryString(key_iv.iv))

  zippedData = decipher.update(data, 'binary', 'binary')
  zippedData += decipher.final('binary')

  Zlib.unzip new Buffer(zippedData, 'binary'), (err, res) ->

    return next err if err?
    
    next null, res.toString()

exports.InbandMessageFormat = 
  Normal: 0
  LZF   : 1

###
# compress using lzf and encrypt
# params
#   message: A string
#   key_iv: A object includes key and iv ({key: 'xxx', iv: 'xxx'}).
# return
#   A buffer object
###
exports.lzfAndEncrypt = (message, key_iv) ->
      
  key_iv = key_iv ? ZMQKey.key_iv 
  cipher = Crypto.createCipheriv("aes-128-cbc", hexToBinaryString(key_iv.key), hexToBinaryString(key_iv.iv))
  
  originalBuffer = new Buffer(message)
  lzfedBuffer = Lzf.compress(originalBuffer)
  head = new Buffer(1)
  
  if originalBuffer.length > lzfedBuffer + 1
    head.writeUInt8(exports.InbandMessageFormat.LZF, 0)
    messageBuffer = Buffer.concat [head, lzfedBuffer], head.length + lzfedBuffer.length
  else
    head.writeUInt8(exports.InbandMessageFormat.Normal, 0)
    messageBuffer = Buffer.concat [head, originalBuffer], head.length + originalBuffer.length

  result = cipher.update(messageBuffer.toString('binary'), 'binary', 'binary')
  result += cipher.final('binary')

  return new Buffer(result, 'binary')

###
# decrypt and unlzf
# params
#   buffer: A buffer object
#   key_iv: A object includes key and iv ({key: 'xxx', iv: 'xxx'}).
# return
#   A string
###
exports.decryptAndUnlzf = (buffer, key_iv) ->

  key_iv = key_iv ? ZMQKey.key_iv 
  data = buffer.toString('binary')

  decipher = Crypto.createDecipheriv("aes-128-cbc", hexToBinaryString(key_iv.key), hexToBinaryString(key_iv.iv))

  decipheredData = decipher.update(data, 'binary', 'binary')
  decipheredData += decipher.final('binary')

  decipheredBuffer = new Buffer(decipheredData, 'binary')
  head = decipheredBuffer.readUInt8(0)
  messageBuffer = decipheredBuffer.slice(1)

  if head is exports.InbandMessageFormat.LZF
    return Lzf.decompress(messageBuffer)
  else
    return messageBuffer.toString()
    
###
# decrypt a string
# params
#   buffer: buffer: A buffer object
#   key_iv: A object includes key and iv ({key: 'xxx', iv: 'xxx'}).
# return
#   A string
###
exports.decrypt = (buffer, key_iv) ->
  data = buffer.toString('binary')

  decipher = Crypto.createDecipheriv("aes-128-cbc", hexToBinaryString(key_iv.key), hexToBinaryString(key_iv.iv))
  result = decipher.update(data, 'binary', 'utf8')
  result += decipher.final('utf8')
  return result

###
# Datetime
###
exports.UTCString = (date) ->
  d = date ? (new Date)

  year = d.getUTCFullYear().toString()
  year = ('000' + year).slice(-4)

  month = (d.getUTCMonth() + 1).toString()
  month = ('0' + month).slice(-2)

  days = d.getUTCDate().toString()
  days = ('0' + days).slice(-2)

  hours = d.getUTCHours().toString()
  hours = ('0' + hours).slice(-2)

  minutes = d.getUTCMinutes().toString()
  minutes = ('0' + minutes).slice(-2)

  seconds = d.getUTCSeconds().toString()
  seconds = ('0' + seconds).slice(-2)

  return year + month + days + 'T' + hours + minutes + seconds + 'Z'

exports.createString = (ch, length) ->
  return Array(length + 1).join ch

OLD_TS_BY_CATEGORY = {}
exports.getTimestamp = (category) ->

  getNewTS = () ->
    d = new Date
    ms = d.getMilliseconds()
    d.getTime() * 1000 + ms

  category = category ? "DEFAULT_TS"

  new_ts = getNewTS()
  old_ts = OLD_TS_BY_CATEGORY[category] ? 0

  if new_ts <= old_ts 
    new_ts = old_ts + 1
  
  OLD_TS_BY_CATEGORY[category] = new_ts
  
  return new_ts.toString()

exports.redisArrayToObject = (arr) ->
  result = {}
  len = arr.length

  for i in [0..len-1] by 2
    result[arr[i]] = arr[i+1]

  return result

exports.splitTagKey = (tagKey) ->
  TAG_SPLIT_CHAR = ':'
  palceholder = '^!@wer^'

  str = tagKey.replace "\\#{TAG_SPLIT_CHAR}", palceholder
  tempArr = str.split TAG_SPLIT_CHAR
  return (a.replace(palceholder, TAG_SPLIT_CHAR) for a in tempArr)

exports.keyToTagIdx = (tagKey) ->
  tempArr = exports.splitTagKey tagKey

  user_id = tempArr[0]
  category = tempArr[1]

  return ( category + TAG_SPLIT_CHAR + a for a in tempArr.slice(2) ).unique()