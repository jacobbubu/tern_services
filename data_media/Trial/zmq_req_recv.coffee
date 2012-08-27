zmq = require('zmq')
sock = zmq.socket('req')

sock.identity = "queue"

sock.bindSync('tcp://127.0.0.1:3001')
console.log('Client bound to port 3001')

###
setInterval ->
  message = process.pid + ": " + counter
  sock.send message
  counter++
  #console.log "Send: " + message
, 500
###
sock.on 'message', (msg) ->
  console.log msg.toString()

sock.on 'error', (err) ->
  console.log err.toString()
