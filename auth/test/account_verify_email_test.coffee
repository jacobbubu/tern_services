should        = require 'should'
BrokersHelper = require('tern.central_config').BrokersHelper

DB            = null
Accounts      = null
accountDB     = null

TestUserObject = 
  user_id   : 'tern_test_user_01'
  email     : 'tern_test_user_01@tern.im'
  password  : '1Nick1'
  locale    : 'zh-Hans-CN'
  data_zone : 'beijing'

describe 'Account_mod Verify Email Test', () ->

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        DB          = require('tern.database')
        Accounts    = require '../lib/models/account_mod'
        done()

  describe '#Prepare data', () ->
    it 'Delete existing user (if has)', (done) -> 
      Accounts.delete TestUserObject.user_id, (err, res) ->
        should.not.exist err
        (res in [0, 1]).should.be.true
        done()

    it 'Create new test user', (done) -> 
      user_object = TestUserObject
        
      Accounts.signup "tern_iPhone", user_object, (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        
        res.should.have.property('result')
        res.result.should.have.property('access_token')
        res.result.should.have.property('token_type')
        res.result.should.have.property('expires_in')
        res.result.should.have.property('refresh_token')

        console.log ''
        console.log "\t#{user_object.user_id}/tern_iPhone/access_token:\t#{res.result.access_token}"
        console.log "\t#{user_object.user_id}/tern_iPhone/refresh_token:\t#{res.result.refresh_token}"

        accountDB = DB.getDB 'accountDB'
        accountDB.exists "users/#{user_object.user_id}", (err, res) ->
          res.should.equal(1)
          accountDB.hgetall "users/#{user_object.user_id}", (err, res) -> 
            res.locale.should.equal(user_object.locale)
            res.lang.should.equal('zh')
            res.lang_script.should.equal('hans')
            res.currency.should.equal('CNY')
            res.region.should.equal('CN')
            res.data_zone.should.equal(user_object.data_zone)
            done()

  describe '#verifyEmail', () ->
    it 'Shoud be success', (done) ->
      user_object = TestUserObject
      Accounts.verifyEmail user_object.user_id, (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        done()

    it 'Bad user_id', (done) ->
      user_id = ''
      Accounts.verifyEmail user_id, (err, res) ->
        should.not.exist err
        res.status.should.equal(-1)
        res.error.should.eql 
          user_id: ['LENGTH', 'PATTERN']
        done()

    it 'Make email verified manually', (done) ->
      accountDB = DB.getDB 'accountDB'
      userKey = 'users/' + TestUserObject.user_id

      accountDB.hset userKey, 'email_verified', 'true', (err, res) ->
        should.not.exist err
        res.should.equal(1)
        done()

    it 'Verified already', (done) ->
      user_object = TestUserObject
      Accounts.verifyEmail user_object.user_id, (err, res) ->
        should.not.exist err
        res.status.should.equal(1)
        done()

  describe '#Clean', () ->
    it 'Delete test user', (done) -> 
      Accounts.delete TestUserObject.user_id, (err, res) ->
        should.not.exist err
        (res in [0, 1]).should.be.true
        done()