ports = 
  PerfCounter    : 8125
  Redis          : 6379
  RedisUnix      : "/tmp/redis.sock"
  MongoDB        : 27017
  CentralAuthWS: 
    host  : "localhost"
    port  : 8080
  CentralAuthZMQ:
    host  : "127.0.0.1"
    port  : 3000  
  DataWS:
    host  : "localhost"
    port  : 8181
  DataZMQ:
    host  : "127.0.0.1"
    port  : 3001
  MediaWeb:
    host  : "localhost"
    port  : 8281
  MediaDB:
    host  : "127.0.0.1"
    port  : 27017

ports.CentralAuthWS.uri = "ws://#{ports.CentralAuthWS.host}:#{ports.CentralAuthWS.port}/1/websocket"
ports.CentralAuthZMQ.uri = "tcp://#{ports.CentralAuthZMQ.host}:#{ports.CentralAuthZMQ.port}"
ports.DataWS.uri = "ws://#{ports.DataWS.host}:#{ports.DataWS.port}/1/websocket"
ports.DataZMQ.uri = "tcp://#{ports.DataZMQ.host}:#{ports.DataZMQ.port}"
ports.MediaWeb.uri = "http://#{ports.MediaWeb.host}:#{ports.MediaWeb.port}"
ports.DataZone = 'beijing'

module.exports = ports
