process.title = 'Tern.DataMedia'

BrokersHelper = require('tern.central_config').BrokersHelper
Datazones = require 'tern.data_zones'

argv = require('optimist')
  .default('g_req', 'tcp://127.0.0.1:21001')
  .default('g_sub', 'tcp://127.0.0.1:21002')
  .default('z_req', 'tcp://127.0.0.1:21101')
  .default('z_sub', 'tcp://127.0.0.1:21102')
  .argv

globalConfigOpts = 
  requester:  argv.g_req
  subscriber: argv.g_sub

zoneConfigOpts = 
  requester:  argv.z_req
  subscriber: argv.z_sub

BrokersHelper.init globalConfigOpts, zoneConfigOpts, () ->
  console.log "Global config from #{argv.g_req}" 
  console.log "Zone config from #{argv.z_req}"
  console.log require('tern.logo')('Data Media. 0.1')
    
  dataZone = Datazones.currentDataZone()

  wsArgv = Datazones.getWebSocketBind dataZone
  wsArgv.data_zone = dataZone
  require('./ws_server').start wsArgv

  mediaArgv = Datazones.getMediaBind dataZone
  require('./media_server').start mediaArgv

  zmqArgv = Datazones.getZMQBind dataZone
  require('./zmq_server').start zmqArgv