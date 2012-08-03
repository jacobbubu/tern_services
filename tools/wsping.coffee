WebSocketClient = require('websocket').client

endpoint = process.argv[2]

unless endpoint?
  console.log "Usgae: coffee wsping tcp://localhost:8181"
  process.exit(0)
else


# This code has problems


ping = ->
  client = new WebSocketClient()

  client.on 'connectFailed', (error) ->
    throw new Error("Connection error unexpectly. #{error.toString()}")

  client.on 'connect', (connection) ->

    connection.on 'message', (message) ->
      if recvFn?
        recvFn JSON.parse WSMessageHelper.parse(message)

    connection.on 'close', (reasonCode, description)-> 


  client.connect endpoint
  , ''
  , null
  , null

