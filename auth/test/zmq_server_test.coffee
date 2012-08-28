should          = require 'should'
Path            = require 'path'
BrokersHelper   = require('tern.central_config').BrokersHelper

Log             = null
SpawnServerTest = null
ZMQSender       = null
Accounts        = null

serverPath = Path.resolve __dirname, '../lib/index.js'

endpoint = null

describe 'Auth. ZMQ Server Unit Test', () ->

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        Log             = require('tern.test_utils').test_log
        SpawnServerTest = require('tern.test_utils').spawn_server
        ZMQSender       = require('tern.zmq_helper').zmq_sender
        Accounts        = require '../lib/models/account_mod'

        {host, port}    = BrokersHelper.getConfig('centralAuth/zmq/connect').value
        endpoint = "tcp://#{host}:#{port}"
        console.log "endpoint", endpoint

        done()

  describe.skip '#Start Auth. ZMQ Server', () ->
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
        response.response.status.should.equal(200)

        done()

  describe '#tokenAuth', () ->
    it "Should be fail. status = 404", (done) ->
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
        response.response.status.should.equal(404)

        done()

  describe.skip '#Stop Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()