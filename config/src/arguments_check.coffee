IPUtils = require 'tern.ip_utils'

argv = require('optimist')
  .default('host', '*')
  .default('res_port', 21001)
  .default('pub_port', 21002)
  .usage('Usage: $0 --host [192.168.1.10] --res_port [21001] --pub_port [21002]')
  .argv

module.exports.getEndpoints = ->
  errMessage = null

  if argv.host isnt '*' and IPUtils.verify(argv.host) isnt true 
    errMessage = 'Bad parameter of --host'
  else
    unless 1024 <= argv.res_port <= 65535
      errMessage 'Bad parameter of --res_port'
    else
      unless 1024 <= argv.pub_port <= 65535
        errMessage 'Bad parameter of --pub_port'
      else
        if argv.res_port is argv.pub_port
          errMessage 'Bad parameter: --res_port can not equal --pub_port'
        else
          resEndpoint = "tcp://" + argv.host + ":" + argv.res_port
          pubEndpoint = "tcp://" + argv.host + ":" + argv.pub_port

          return host: argv.host, resEndpoint: resEndpoint, pubEndpoint: pubEndpoint

  throw new Error (errMessage)

          
          
