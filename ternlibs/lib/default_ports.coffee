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
    host  : "localhost"
    port  : 8080
  CentralAuthZMQ:
    host  : "127.0.0.1"
    port  : 3000  
  DataWS:
    host  : "localhost"
    port  : 8180
  DataZMQ:
    host  : "127.0.0.1"
    port  : 3000
  MediaWeb:
    host  : "localhost"
    port  : 8280
  MediaMongo:
    host  : "127.0.0.1"
    port  : 27017

ports.CentralAuthWS.uri = "ws://#{ports.CentralAuthWS.host}:#{ports.CentralAuthWS.port}/1/websocket"
ports.CentralAuthZMQ.uri = "tcp://#{ports.CentralAuthZMQ.host}:#{ports.CentralAuthZMQ.port}"

ports.DataZone = 'beijing'
ports.DataWS.uri = getURI 'websocket'
ports.DataZMQ.uri = getURI 'zmq'
ports.MediaWeb.uri = getURI 'media'

module.exports = ports
