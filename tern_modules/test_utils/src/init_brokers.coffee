Broker = require('tern.central_config').Broker 
Sync = require 'sync'

module.exports.init = (next) ->
  
  if global.globalBroker? or global.zoneBroker?
    next and next()
  else
    console.log 'initializing config'
    
    globalConfigOpts = 
      requester:  'tcp://127.0.0.1:21001'
      subscriber: 'tcp://127.0.0.1:21002'

    zoneConfigOpts = 
      requester:  'tcp://127.0.0.1:21101'
      subscriber: 'tcp://127.0.0.1:21102'

    globalBroker = new Broker globalConfigOpts
    zoneBroker = new Broker zoneConfigOpts

    process.on 'exit', ->
      delete global.globalBroker
      delete global.zoneBroker

    globalBroker.init (configFile) ->
      global.globalBroker = globalBroker

      zoneBroker.init (configFile) ->
        global.zoneBroker = zoneBroker
        next and next()

module.exports.initSync = ->
  Sync ->
    module.exports.init()