module.exports = 
  centralAuth:
    websocket:
      bind:
        host: '*'
        port: 22000
      connect:
        host: 'localhost'
        port: 22000
    zmq:
      bind:
        host: '*'
        port: 22100
      connect:
        host: '127.0.0.1'
        port: 22100    
  dataZones:
    beijing:
      websocket:
        bind:
          host: '*'
          port: 23000
        connect:
          host: 'localhost'
          port: 23000
      media:
        bind:
          host: '*'
          port: 23100
        connect:
          host: 'localhost'
          port: 23100          
      zmq:
        bind:
          host: '*'
          port: 23200
        connect:
          host: '127.0.0.1'
          port: 23200