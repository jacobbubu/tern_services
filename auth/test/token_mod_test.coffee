should      = require 'should'
DB          = require('ternlibs').database
Tokens      = require '../models/token_mod'
Async       = require "async"

describe 'Token_mod Test', () ->
  
  oldAccessToken = null
  oldRefreshToken = null

  timeout = 3600

  successCheck = (err, res) ->
    should.not.exist err
    res.should.have.property('status')
    res.status.should.equal(0)
    res.should.have.property('result')
    res.result.should.have.property('access_token')
    res.result.should.have.property('refresh_token')

  failureCheck = (err, res, status) ->
    should.not.exist err
    res.should.have.property('status')
    res.status.should.equal(status)

  describe '#new', () ->
    it "Success", (done) ->
      Tokens.new 'tern_user_01', 'tern_iPhone', 'addMemo delMemo', timeout, (err, res) ->

        successCheck err, res

        oldAccessToken  = res.result.access_token
        oldRefreshToken = res.result.refresh_token

        done()

  describe '#tokenAuth(In-band)', () ->
    it "Success: status = 0", (done) ->

      Tokens.tokenAuth oldAccessToken, (err, res) ->
        should.not.exist err
        res.should.have.property('status')
        res.status.should.equal(0)
        res.should.have.property('result')
        res.result.should.have.property('access_token')
        res.result.access_token.should.equal(oldAccessToken)
        res.result.should.have.property('expires_in')

        (res.result.expires_in <= timeout).should.be.true
        
        done()

    it "Failed: status = -2", (done) ->

      Tokens.tokenAuth 'bad token', (err, res) ->
        should.not.exist err
        res.should.have.property('status')
        res.status.should.equal(-2)
        
        done()

  describe '#refresh', () ->
    it "Success: status = 0", (done) ->

      Tokens.refresh 'tern_iPhone', oldRefreshToken, 61, (err, res) ->

        successCheck err, res
        
        res.result.refresh_token.should.equal(oldRefreshToken)
        res.result.access_token.should.not.equal(oldAccessToken)

        done()

    it "Bad_Client_id: status = -3", (done) ->

      Tokens.refresh 'Bad_Client_id', oldRefreshToken, 61, (err, res) ->
        
        failureCheck err, res, -3

        done()

    it "Bad_Refresh_Token: status = -3", (done) ->

      Tokens.refresh 'tern_iPhone', 'Bad_Refresh_Token', 61, (err, res) ->
        
        failureCheck err, res, -3

        done()

  describe '#refresh 100 times', () ->
    it "Success", (done) ->

      i = 0
      Async.whilst(
          -> i < 100
        , (next) ->
          i++
          Tokens.refresh 'tern_iPhone', oldRefreshToken, 61, (err, res) ->

            successCheck err, res

            res.result.refresh_token.should.equal(oldRefreshToken)
            res.result.access_token.should.not.equal(oldAccessToken)

            next()
        , ->
          done()
      )
  ###