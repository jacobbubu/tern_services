Broker = require '../lib/broker'
Server = require '../lib/server'

Fiber = require 'fibers'

brokerInit = Fiber (broker) ->

  fiber = Fiber.current

  broker = new Broker

  broker.init () ->
    Fiber.yield
    
  Fiber.yield(broker)
  
server = new Server

broker = brokerInit.run()

console.log 'returning control to node event loop'

path1 = 'Logger'
path2 = 'Logger/transports'
path3 = 'Logger/transports/console'

config1 = broker.getConfig path1
###
broker.init (congigFile) ->
  path1 = 'Logger'
  path2 = 'Logger/transports'
  path3 = 'Logger/transports/console'

  config1 = broker.getConfig path1
  config1.on 'changed', (oldValue, newValue) ->
    console.log 'config1'
    console.dir oldValue
    console.dir newValue

  config2 = broker.getConfig path2
  config2.on 'changed', (oldValue, newValue) ->
    console.log 'config2'
    console.dir oldValue
    console.dir newValue

  config3 = broker.getConfig path3
  config3.on 'changed', (oldValue, newValue) ->
    console.log 'config3'
    console.dir oldValue
    console.dir newValue
###

###
  #console.log path1, (broker.getConfig path1)
  #console.log path2, (broker.getConfig path2)
  #console.log path3, (broker.getConfig path3)