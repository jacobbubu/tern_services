Log        = require 'tern.logger'
Utils      = require 'tern.utils'
PJ         = require 'tern.prettyjson'
ZMQKey     = require './zmq_key'

###
  signature1:
    socket, status, req
  signature2:
    socket, req, res      
###
send = (socket, arg1, arg2) ->

  if Utils.type(arg1) is 'number'
    status = arg1
    req = arg2

    responseObj =
      req_ts: req?.req_ts ? ''
      response:
        method: req?.request?.method ? ''
        status: status
  else
    req = arg1
    res = arg2

    responseObj = res
    responseObj.req_ts = req?.req_ts ? ''
    responseObj.response.method = req?.request?.method ? ''

  strResponse = JSON.stringify(responseObj)
  resBuffer = Utils.lzfAndEncrypt strResponse, ZMQKey.key_iv

  socket.send resBuffer
  Log.info "ZMQ Responder:\r\n-\r\n#{PJ.render req}\r\n#{PJ.render responseObj}\r\nLength: #{new Buffer(strResponse).length}/#{resBuffer.length}"

module.exports.send = send