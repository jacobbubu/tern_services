should        = require 'should'
BrokersHelper = require('tern.central_config').BrokersHelper
TestData      = require './test_data'
Token         = null

describe 'Token Agent Unit Test', () ->
  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        Token = require '../lib/agents/token_agent'
        done()

  describe '#getInfo', () ->
    it "Should be success", (done) ->
      Token.getInfo TestData.access_token, (err, res) ->
        res.access_token.should.equal(TestData.access_token)
        res.user_id.should.equal(TestData.user_id)
        res.should.have.property('scope')
        done()

    it "Bad access token", (done) ->
      Token.getInfo 'xxxxxxxx', (err, res) ->
        err.name.should.equal("ResourceDoesNotExistException")
        done()
