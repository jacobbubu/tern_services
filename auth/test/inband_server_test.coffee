should      = require 'should'
Log         = require './test_log'
Accounts    = require '../models/account_mod'
spawn       = (require 'child_process').spawn
path        = require 'path'

ZMQSender   = require('ternlibs').ZMQSender
ZMQUtils    = require '../zmqfacets/zmq_utils'

endpoint = "tcp://127.0.0.1:3001"

main = path.resolve __dirname, '../index.coffee'
authServer = null

describe 'Auth. In-band Server Unit Test', () ->

  describe '#Start Auth. Server', () ->
    it "Should be success", (done) ->
      authServer = spawn 'coffee', [main]

      authServer.stdout.on 'data', (data) ->
        message = data.toString()

        Log.serverLog message

        if /Auth. In-band Server is listening on port/i.test message
          done()

      authServer.stderr.on 'data', (data) ->
        message = data.toString()

        Log.serverError message

    
  describe '#Ping', () ->
    it "Should be success", (done) ->
      sender = new ZMQSender('tcp://127.0.0.1:3001', ZMQUtils.key_iv, null, 60 * 1000)

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
      sender = new ZMQSender('tcp://127.0.0.1:3001', ZMQUtils.key_iv, null, 60 * 1000)

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

  describe '#Kill Service', () ->
    it "SIGINT", (done) ->
      if authServer?
        authServer.kill 'SIGINT'
        authServer = null

      done()



