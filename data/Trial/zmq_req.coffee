zmq = require('zmq')
sock = zmq.socket('req')

sock.identity = "boy one"

sock.connect('tcp://127.0.0.1:3001')
console.log('Client connected to port 3001')

counter = 0
totalCount = 100

for i in [1..totalCount]
  message = process.pid + ": " + counter.toString()
  sock.send message
  counter++

console.log "#{totalCount} messages sent."
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

