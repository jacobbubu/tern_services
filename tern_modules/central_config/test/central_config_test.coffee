should = require 'should'
Broker = require '../lib/broker'
Server = require '../lib/server'
Path   = require 'path'
FS     = require 'fs'

configFilename = Path.resolve __dirname, '/tmp/tern/config_test.coffee'
configDir = Path.dirname configFilename

originalFileContent = """
module.exports = 
  Logger:
    console:
      level     :    0
"""

configFileContent1 = """
module.exports = 
  Logger:
    console:
      level     :    2
"""

server = null
broker = null
config1 = null
config2 = null
config3 = null

describe "Central Config Unit Test", ->
  before () ->
    try
      FS.mkdirSync configDir
    catch err
      unless err.code and err.code is 'EEXIST'
        throw err

    FS.writeFileSync configFilename, originalFileContent

  after () ->
    FS.unlinkSync configFilename
    FS.rmdirSync configDir

  it "Start Server", (done) ->
    server = new Server configFilename: configFilename
    done()

  it "Broker init", (done) ->
    broker = new Broker
    broker.init (congigFile) ->
      congigFile.Logger.console.level.should.equal 0
      done()

  it "Config objects init", (done) ->
    path1 = 'Logger'
    path2 = 'Logger/console'
    path3 = 'Logger/console/level'

    config1 = broker.getConfig path1
    config2 = broker.getConfig path2
    config3 = broker.getConfig path3

    config1.value.console.level.should.equal 0
    config2.value.level.should.equal 0
    config3.value.should.equal 0

    done()

  it "Change file", (done) ->
    count = 3
    config1.on 'changed', (oldValue, newValue) ->
      oldValue.console.level.should.equal 0
      newValue.console.level.should.equal 2
      count--
      done() if count is 0 

    config2.on 'changed', (oldValue, newValue) ->
      oldValue.level.should.equal 0
      newValue.level.should.equal 2
      count--
      done() if count is 0       

    config3.on 'changed', (oldValue, newValue) ->
      oldValue.should.equal 0
      newValue.should.equal 2
      count--
      done() if count is 0 

    setTimeout ->
      FS.writeFileSync configFilename, configFileContent1
    , 1000
