process.title = 'Tern.DataMedia'

###
#  Get WebSocket Server Listening Port from Command Line
###
DefaultPorts = require('ternlibs').default_ports

argv = require('optimist')
  .default('ws_host', DefaultPorts.DataWS.host)
  .default('ws_port', DefaultPorts.DataWS.port)
  .default('media_host', DefaultPorts.MediaWeb.host)
  .default('media_port', DefaultPorts.MediaWeb.port)
  .default('data_zone', DefaultPorts.DataZone)
  .argv

console.log "Data Zone:", argv. data_zone
require('./ws_server').start argv
require('./media_server').start argv
require('./zmq_server').start argv
console.log require('ternlibs').tern_logo('DataMedia. 0.1')