process.title = 'Tern.Auth'

###
#  Get WebSocket Server Listening Port from Command Line
###
DefaultPorts = require('ternlibs').default_ports

argv = require('optimist')
  .default('ws_host', DefaultPorts.CentralAuthWS.host)
  .default('ws_port', DefaultPorts.CentralAuthWS.port)
  .default('zmq_host', DefaultPorts.CentralAuthZMQ.host)
  .default('zmq_port', DefaultPorts.CentralAuthZMQ.port)
  .argv

require('./ws_server').start argv
require('./zmq_server').start argv
console.log require('ternlibs').tern_logo('Auth. 0.1')