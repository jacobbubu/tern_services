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
  CentralAuth:
    host: '127.0.0.1'
    port: 3001    
  TokenCacheDB:
    host: "localhost"
    port: 6379
    dbid: 3
  UserDataDB:
    host: "localhost"
    port: 6379
    dbid: 4
