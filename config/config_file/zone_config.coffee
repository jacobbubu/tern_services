module.exports =
  dataZone: 'beijing' 
  logger:
    transports:
      ###
      console:
        colorize  : true
        level     :    0
        timestamp : true
      ###
      file:
        filename  : './log/xxxx1.log'
        maxsize   : 51200
        maxFiles  : 10
        timestamp : true
        level     :    0
  perfCounter:
    host: 'localhost'
    port: 8125
  clientModel:
    "default":
      ttl: 24 * 3600         # seconds for 24 hours
      grant_type: "code"    
  databases:
    clientDB:
      host: "localhost"
      port: 6379
      dbid: 0
    accountDB:
      host: "localhost"
      port: 6379
      dbid: 1    
      #unixsocket: "/tmp/redis.sock"
    redisLockDB:
      host: "localhost"
      port: 6379
      dbid: 5
    tokenCacheDB:
      host: "localhost"
      port: 6379
      dbid: 3
    userDataDB:
      host: "localhost"
      port: 6379
      dbid: 4
    mediaMongo:
      host: "127.0.0.1"
      port: 27017