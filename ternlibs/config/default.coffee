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
    port: 8125
  TestDB:
    #host: "localhost"
    port: 6379
    dbid: 0
    unixsocket: "/tmp/redis.sock"