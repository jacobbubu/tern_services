Log   = require './logger'
Utils = require './utils'

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
  resBuffer = Utils.lzfAndEncrypt strResponse

  socket.send resBuffer
  Log.info "ZMQ Responder: req: #{JSON.stringify req} res: #{strResponse} Length: #{new Buffer(strResponse).length}/#{resBuffer.length}"

exports = module.exports.send = send