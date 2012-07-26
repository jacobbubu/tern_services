should    = require 'should'
Token     = require '../models/token_agent'
TestData  = require './test_data'

describe 'Token Agent Unit Test', () ->
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
