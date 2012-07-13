module.exports = 
  Logger:
    transports:
      console:
        colorize  : false
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
    port: 8125
  ClientDB:
    host: "localhost"
    port: 6379
    dbid: 0
  AccountDB:
    host: "localhost"
    port: 6379
    dbid: 1    
    #unixsocket: "/tmp/redis.sock"
  ClientModel:
    "default":
      ttl: 24 * 3600         # seconds for 24 hours
      grant_type: "code"
