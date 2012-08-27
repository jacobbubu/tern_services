process.title = 'Tern.GlobalConfig'

Server    = require('tern.central_config').Server
Path      = require 'path'
Argvs     = require './arguments_check'

try  
  {host, resEndpoint, pubEndpoint} =  Argvs.getEndpoints()   
catch err
  console.error err.toString()
  return

console.log require('tern.logo')('Global Config. 0.1')
      
options = 
  configFilename: Path.resolve __dirname, '../config_file/global_config.coffee'
  responder: resEndpoint
  publisher: pubEndpoint

server = new Server options
