should    = require 'should'
Token     = require '../models/token_mod'
TestData  = require './test_data'

describe 'Token Cache Unit Test', () ->
  describe '#getInfo', () ->
    it "Should be success", (done) ->
      Token.getInfo 'SpEtVGG2Pwl0Z4Wobxhsdd', (err, res) ->
        res.access_token.should.equal("SpEtVGG2Pwl0Z4Wobxhsdd")
        res.user_id.should.equal("tern_test_persistent")
        res.should.have.property('scope')
        done()

    it "Bad access token", (done) ->
      Token.getInfo 'xxxxxxxx', (err, res) ->
        err.name.should.equal("ResourceDoesNotExistException")
        done()
