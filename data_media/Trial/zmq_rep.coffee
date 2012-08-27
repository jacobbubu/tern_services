zmq = require('zmq')

setTimeout () -> 
    console.log('Timeout')
  , 1

process.title = 'ZMQ_REP'

sock = zmq.socket('router')
sock.identity = "server"

sock.bindSync('tcp://127.0.0.1:3001')
console.log('Server bound to port 3001')

sendLater = (buffer) ->
  sock.send buffer
  console.log 'Server sent: ' + buffer.toString()  

sock.on 'message', (buffer) ->  
  console.log 'Server received: ' + buffer.toString()
  sendLater(buffer)
  ###
  setTimeout () -> 
    sendLater(buffer)
  , 1000
  ###

sock.on 'error', (err) ->
  console.log err.toString()

sock.on 'bind', () ->
  console.log('Server bound to port 3001')
