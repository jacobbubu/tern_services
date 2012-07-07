Utils   = require('ternlibs').utils
zmq = require('zmq')
sock = zmq.socket('rep')

process.title = 'ZMQ_REP'

key_iv =
  key : "8eb5575e940893ebd78c8df499e6541f"
  iv : "1f07c9e9866d53cf5f1005464fc8f474"

sock.bindSync('tcp://127.0.0.1:3001')
console.log('Server bound to port 3001')

sock.on 'message', (buffer) ->
  
  Utils.decryptAndUncompress buffer, key_iv, (err, res) ->
    console.log 'Received: ' + res.length
    sock.send buffer

    ###
    setTimeout ->
      sock.send buffer
    , Math.floor Math.random() * 10
    ###
