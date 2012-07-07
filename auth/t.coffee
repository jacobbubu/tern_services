WebSocketClient = require('websocket').client

client = new WebSocketClient()

client.on 'connectFailed', (error) ->
  console.log 'Connect Error: ' + error.toString()

client.on 'connect', (connection) ->
    console.log 'WebSocket client connected'
    connection.on 'error', (error) ->
      console.log "Connection Error: " + error.toString()
    
    connection.on 'close', -> 
      console.log 'auth Connection Closed'

    connection.on 'message', (message) ->
      if (message.type is 'utf8') 
        console.log  "Received: '" + message.utf8Data + "'"

    sendNumber = ->
      if connection.connected
          number = Math.round(Math.random() * 0xFFFFFF)
          connection.sendUTF number.toString()
          setTimeout sendNumber, 500

    unique = ->
      if connection.connected
        req = 
          request:
            req_ts: (+new Date).toString()
            method: 'auth.unique'
            data:
              user_id: 'tern_test_user_01'

        connection.sendUTF JSON.stringify(req)
        setTimeout unique, 500
    
    unique()

client.connect 'ws://localhost:8080/'
  , 'auth'
  , null
  , "Client, client_id = tern_iPhone;client_secret =Ob-Kp_rWpnHbQ0h059uvJX"
  , 'zh'

