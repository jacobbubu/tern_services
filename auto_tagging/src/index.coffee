process.title = 'Tern.AutoTagging'

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
  console.log require('tern.logo').AutoTagging('0.1')
    
  argv.router = BrokersHelper.getEndpointFromPath 'autoTagging/router/bind'
  argv.dealer = BrokersHelper.getEndpointFromPath 'autoTagging/dealer/bind'

  require('./ats_server').start argv