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

module.exports.init = (serviceType, next) ->

  BrokersHelper.init globalConfigOpts, zoneConfigOpts, ->
    dataZone = Datazones.currentDataZone()

    switch serviceType
      when 'WebSocket'
        argv = Datazones.getWebSocketBind dataZone
      when 'Media'
        argv = Datazones.getMediaBind dataZone
      when 'DataQueues'
        argv = 
          queues: Datazones.getDataQueuesConfig dataZone
          current: dataZone
      when 'MediaQueues'
        argv = 
          queues: Datazones.getMediaQueuesConfig dataZone
          current: dataZone
      else
        next? and next new Error "Unsupported serviceType"

    argv.data_zone = dataZone
    
    next? and next null, argv
    
    
