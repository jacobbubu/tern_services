module.exports =
  dataZone: 'beijing' 
  logger:
    transports:
      console:
        colorize  : true
        level     :    0
        timestamp : true
      file:
        filename  : './log/xxxx.log'
        maxsize   : 1024000
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
  autoTagging:
    router:
      bind:
        protocol: 'tcp'
        host: '*'
        port: 24000
      connect:
        protocol: 'tcp'
        host: '127.0.0.1'
        port: 24000
    dealer:          
      bind:
        protocol: 'ipc'
        host: '/tmp/tern.auto_tagging'
      connect:
        protocol: 'ipc'
        host: '/tmp/tern.auto_tagging'
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
      dbid: 10
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
    userDBShards:
      shard01:
        pattern: "^[a-z]+$"
        host: "localhost"
        port: 6379
        dbid: 4
      shard02:
        pattern: "^[A-Z]+$"
        host: "localhost"
        port: 6379
        dbid: 5
      shard03:
        pattern: "^[^a-zA-Z]+$"
        host: "localhost"
        port: 6379
        dbid: 6       