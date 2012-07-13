Log             = require('ternlibs').test_log
Path            = require 'path'
SpawnServerTest = require('ternlibs').spawn_server_test

should      = require 'should'
Accounts    = require '../models/account_mod'

ZMQSender   = require('ternlibs').ZMQSender

DefaultPorts = require('ternlibs').default_ports

endpoint = DefaultPorts.CentralAuthZMQ.uri

serverPath = Path.resolve __dirname, '../index.coffee'

describe 'Auth. ZMQ Server Unit Test', () ->

  describe '#Start Auth. ZMQ Server', () ->
    it "Spawn Server Process", (done) ->
      SpawnServerTest.start serverPath, /Auth. ZMQ Server is listening on/i, () ->
        done()
    
  describe '#Ping', () ->
    it "Should be success", (done) ->
      sender = new ZMQSender(endpoint)

      message = 
        method: "ping"

      sender.send message, (err, response) ->
        should.not.exist err

        response.should.have.property('response')
        response.response.should.have.property('status')
        response.response.should.have.property('method')
        response.response.method.should.equal(message.method)
        response.response.status.should.equal(0)

        done()

  describe '#tokenAuth', () ->
    it "Should be fail. status = -2", (done) ->
      sender = new ZMQSender(endpoint)

      message = 
        method: "tokenAuth"
        data:
          access_token: 'bad token'

      sender.send message, (err, response) ->
        should.not.exist err

        response.should.have.property('response')
        response.response.should.have.property('status')
        response.response.should.have.property('method')
        response.response.method.should.equal(message.method)
        response.response.status.should.equal(-2)

        done()

  describe '#Stop Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()


