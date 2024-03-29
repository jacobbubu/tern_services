process.title = 'Tern.Auth'

BrokersHelper = require('tern.central_config').BrokersHelper

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
  console.log require('tern.logo').Auth('0.1')
    
  wsArgv = BrokersHelper.getConfig('centralAuth/websocket/bind').value
  require('./ws_server').start wsArgv

  zmqArgv = {}
  zmqArgv.router = BrokersHelper.getEndpointFromPath('centralAuth/zmq/router/bind')
  zmqArgv.dealer = BrokersHelper.getEndpointFromPath('centralAuth/zmq/dealer/bind')
  
  require('./zmq_server').start zmqArgv
