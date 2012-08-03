ZMQSender = require('ternlibs').zmq_sender
should    = require 'should'

endpoint = process.argv[2]

unless endpoint?
  console.log "Usgae: coffee zmqping tcp://127.0.0.1:3000"
  process.exit(0)
else
  sender = new ZMQSender(endpoint, null, null, 1000)

  message = 
    method: "ping"

  count = 6

  ping = ->
    startTime = +new Date

    sender.send message, (err, response) ->
      endTime = +new Date
      
      if err?
        console.error "err occured: " + err.toString()
      else
        response.should.have.property('response')
        response.response.should.have.property('status')
        response.response.should.have.property('method')
        response.response.method.should.equal(message.method)
        response.response.status.should.equal(200)
        console.log "Response in #{endTime - startTime} milliseconds."

      count--
      if count is 0
        process.exit(0)
      else
        process.nextTick(ping)

  ping()