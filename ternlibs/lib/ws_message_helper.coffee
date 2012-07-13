LZF = require './lzf'

###
# @return   none
# @callback next(err) if error occured
#
# @param    WebSocketConnection that websocket server passed-by
# @param    message serialized by string
###

MessageHead =
  TEXT  : 0
  LZF   : 1
  MEDIA : 2

module.exports.send = (connection, message, next) ->

  try
    if connection._tern? and connection._tern.compressMethod is 'lzf'

      lzfMessage = LZF.compress(message)
      originalLength = new Buffer(message).length
      if lzfMessage.length + 1 < originalLength
        head = new Buffer(1)

        #Write Binary message format in first byte
        head.writeUInt8(MessageHead.LZF, 0)

        connection.sendBytes Buffer.concat([head, lzfMessage], head.length + lzfMessage.length), (err) ->
          next err if next?
          return
      else
        connection.sendUTF message, (err) ->
          next err if next?
          return

    else
      connection.sendUTF message, (err) ->
        next err if next?
        return

  catch e
    next e if next?
    return
  
module.exports.parse = (message) ->
  if message.type is 'utf8'
    return message.utf8Data    
  else
    buf = message.binaryData
    if buf.readUInt8(0) is MessageHead.LZF
      return LZF.decompress buf.slice(1)
    else
      return message
  
