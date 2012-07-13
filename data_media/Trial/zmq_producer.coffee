zmq = require('zmq')
sock = zmq.socket('push')

sock.bindSync('tcp://127.0.0.1:3000')
console.log('Producer bound to port 3000')

setInterval () ->
  message = 'sending work' + (new Date).getTime()
  console.log message
  sock.send message
, 500