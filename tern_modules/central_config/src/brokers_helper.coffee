Sync = require 'sync'
Broker = require './broker'

internals = 
  globalBroker: null
  zoneBroker: null

init = (globalConfigOpts, zoneConfigOpts, next) ->
  
  if internals.globalBroker? or internals.zoneBroker?
    return next()

  unless globalConfigOpts?
    globalConfigOpts = 
      requester:  'tcp://127.0.0.1:21001'
      subscriber: 'tcp://127.0.0.1:21002'

  unless zoneConfigOpts?
    zoneConfigOpts = 
      requester:  'tcp://127.0.0.1:21101'
      subscriber: 'tcp://127.0.0.1:21102'

  globalBroker = new Broker globalConfigOpts
  zoneBroker = new Broker zoneConfigOpts

  globalBroker.init (configObj) ->
    zoneBroker.init (configObj) ->
      internals.globalBroker = globalBroker
      internals.zoneBroker = zoneBroker
      next()

getConfig = (path) ->
  zoneBroker = internals.zoneBroker 
  globalBroker = internals.globalBroker

  config = null

  if zoneBroker?
    try
      config = zoneBroker.getConfig path
      return config
    catch e
    
  if globalBroker?
    try
      config = globalBroker.getConfig path
      return config
    catch e

  return config

module.exports.getConfig = (path) ->
  getConfig path

module.exports.init = () ->
  switch arguments.length
    when 0
      globalConfigOpts = null
      zoneConfigOpts = null
      next = null
    when 1
      globalConfigOpts = null
      zoneConfigOpts = null
      next = arguments[0]
    when 2
      globalConfigOpts = arguments[0]
      zoneConfigOpts = null
      next = arguments[1]
    when 3
      globalConfigOpts = arguments[0]
      zoneConfigOpts = arguments[1]
      next = arguments[2]

  init globalConfigOpts, zoneConfigOpts, () ->
    next? and next()