DataZones = require '../consts/data_zones'

getURI = (key) ->
  uri = DataZones[ports.DataZone][key]
  throw new Error("uri does not exist. Data Zone: #{ports.DataZone}, key: #{key}") unless uri?
  uri

ports = 
  PerfCounter    : 8125
  Redis          : 6379
  RedisUnix      : "/tmp/redis.sock"
  MongoDB        : 27017
  CentralAuthWS: 
    host  : "*"
    port  : 8080
  CentralAuthZMQ:
    host  : "*"
    port  : 3000  
  DataWS:
    host  : "*"
    port  : 8180
  DataZMQ:
    host  : "*"
    port  : 3000
  MediaWeb:
    host  : "*"
    port  : 8280
  MediaMongo:
    host  : "127.0.0.1"
    port  : 27017

ports.CentralAuthWS.uri = "ws://127.0.0.1:#{ports.CentralAuthWS.port}/1/websocket"
ports.CentralAuthZMQ.uri = "tcp://127.0.0.1:#{ports.CentralAuthZMQ.port}"

ports.DataZone = 'beijing'
ports.DataWS.uri = getURI 'websocket'
ports.DataZMQ.uri = getURI 'zmq'
ports.MediaWeb.uri = getURI 'media'

module.exports = ports
