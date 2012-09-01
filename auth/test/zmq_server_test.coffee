should          = require 'should'
Path            = require 'path'
BrokersHelper   = require('tern.central_config').BrokersHelper

Log             = null
SpawnServerTest = null
Sender          = null
Accounts        = null

serverPath = Path.resolve __dirname, '../lib/index.js'

endpoint = null

describe 'Auth. ZMQ Server Unit Test', () ->

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        Log             = require('tern.test_utils').test_log
        SpawnServerTest = require('tern.test_utils').spawn_server
        Sender          = require('tern.zmq_reqres').Sender
        Accounts        = require '../lib/models/account_mod'

        endpoint = BrokersHelper.getEndpointFromPath('centralAuth/zmq/router/connect')
        console.log "endpoint", endpoint

        done()

  describe.skip '#Start Auth. ZMQ Server', () ->
    it "Spawn Server Process", (done) ->
      SpawnServerTest.start serverPath, /Auth. ZMQ Server is listening on/i, () ->
        done()
    
  describe '#Reverse', () ->
    it "Should be success", (done) ->
      sender = new Sender router: endpoint

      data = 'Hello'
      sender.send 'Reverse', data, (err, response) ->
        should.not.exist err
        response.should.equal('olleH')
        sender.close()
        done()

  describe '#tokenAuth', () ->
    it "Should be fail. status = 404", (done) ->
      sender = new Sender router: endpoint

      message = 
        access_token: 'bad token'

      sender.send 'TokenAuth', message, (err, response) ->
        should.not.exist err
        response.status.should.equal(404)

        done()

  describe.skip '#Stop Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()