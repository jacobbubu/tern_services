URL = require 'url'
DataZones = require('ternlibs').consts.data_zones
process.title = 'Tern.DataMedia'

###
#  Get WebSocket Server Listening Port from Command Line
###
DefaultPorts = require('ternlibs').default_ports

argv = require('optimist')
  .default('data_zone', DefaultPorts.DataZone)
  .argv

data_zone = argv.data_zone

defaults = 
  'data_zone': data_zone

res = URL.parse DataZones[data_zone].websocket_server
res.hostname = '*' if res.hostname is ''

defaults.ws_host = argv.ws_host ? res.hostname
defaults.ws_port = argv.ws_port ? res.port

res = URL.parse DataZones[data_zone].media_server
res.hostname = '*' if res.hostname is ''

defaults.media_host = argv.media_host ? res.hostname
defaults.media_port = argv.media_port ? res.port

console.log "Data Zone:", data_zone
require('./ws_server').start defaults
require('./media_server').start defaults
require('./zmq_server').start defaults
console.log require('ternlibs').tern_logo('DataMedia. 0.1')