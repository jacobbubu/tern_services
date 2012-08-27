zmq = require('zmq')
sock = zmq.socket('dealer')

sock.identity = "boy one"
sock.hwm = 1

sock.connect('tcp://127.0.0.1:3001')
console.log('Client connected to port 3001')

counter = 0
totalCount = 10

coutdown = totalCount

for i in [1..totalCount]
  message = process.pid + ": " + counter.toString()
  sock.send [new Buffer(""), message]
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
  coutdown -= 1
  process.exit 0 if coutdown is 0

