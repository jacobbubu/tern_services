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
      "websocket": "ws://localhost:8181"
      "zmq": "tcp://127.0.0.1:3011"
      "media": "http://localhost:8281"
      "country": "CN"
    "tokyo":
      "websocket": "ws://localhost:8182"
      "zmq": "tcp://127.0.0.1:3012"
      "media": "http://localhost:8282"
      "country": "JP"
    "singapore":
      "websocket": "ws://localhost:8183"
      "zmq": "tcp://127.0.0.1:3013"
      "media": "http://localhost:8283"
      "country": "SG"
    "virginia":
      "websocket": "ws://localhost:8184"
      "zmq": "tcp://127.0.0.1:3014"
      "media": "http://localhost:8284"
      "country": "US"
    "northern_california":
      "websocket": "ws://localhost:8185"
      "zmq": "tcp://127.0.0.1:3015"
      "media": "http://localhost:8285"
      "country": "US"
    "ireland":
      "websocket": "ws://localhost:8186"
      "zmq": "tcp://127.0.0.1:3016"
      "media": "http://localhost:8286"
      "country": "IE"
    "sao_paulo":
      "websocket": "ws://localhost:8187"
      "zmq": "tcp://127.0.0.1:3017"
      "media": "http://localhost:8287"
      "country": "BR" 