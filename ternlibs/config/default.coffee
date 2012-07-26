module.exports = 
  Logger:
    transports:
      console:
        colorize  : true
        level     :    0
        timestamp : true
      file:
        filename  : './xxxx1.log'
        maxsize   : 51200
        maxFiles  : 10
        timestamp : true
        level     :    0
  PerfCounter:
    host: 'localhost'
  TestDB:
    #host: "localhost"
    port: 6379
    dbid: 0
    unixsocket: "/tmp/redis.sock"
  DataZones:
    "beijing":
      "websocket": "wss://data.beijing.tern.im/v1"
      "zmq": "tcp://127.0.0.1:3011"
      "country": "CN"
    "tokyo":
      "websocket": "wss://data.tokyo.tern.im/v1"
      "zmq": "tcp://127.0.0.1:3012"
      "country": "JP"
    "singapore":
      "websocket": "wss://data.singapore.tern.im/v1"
      "zmq": "tcp://127.0.0.1:3013"
      "country": "SG"
    "virginia":
      "websocket": "wss://data.virginia.tern.im/v1"
      "zmq": "tcp://127.0.0.1:3014"
      "country": "US"
    "northern_california":
      "websocket": "wss://data.northern_california.tern.im/v1"
      "zmq": "tcp://127.0.0.1:3015"
      "country": "US"
    "ireland":
      "websocket": "wss://data.ireland.tern.im/v1"
      "zmq": "tcp://127.0.0.1:3016"
      "country": "IE"
    "sao_paulo":
      "websocket": "wss://data.sao_paulo.tern.im/v1"
      "zmq": "tcp://127.0.0.1:3017"
      "country": "ZA"    
