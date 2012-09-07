should        = require 'should'
fs            = require 'fs'
BrokersHelper = require('tern.central_config').BrokersHelper

DB            = null
Accounts      = null

TestUserObject = 
  user_id   : 'tern_test_user_01'
  email     : 'tern_test_user_01@tern.im'
  password  : '1Nick1'
  locale    : 'zh-Hans-CN'
  data_zone : 'beijing'

describe 'Account_mod Test', () ->

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        DB          = require('tern.database')
        Accounts    = require '../lib/models/account_mod'
        done()

  describe '#signup', () ->

    it 'BAD USER_ID/EMAIL/PASSWORD/DATA_ZONE/LOCALE, SAME_AS_USER_ID', (done) -> 

      user_object = 
        user_id   : '__'
        email     : '__'
        password  : '__'
        locale    : 'UNKNOWN-BADSCRIPT-LOCALE'
        data_zone : 'BAD_DATA_ZONE'

      Accounts.signup "tern_iPhone", user_object, (err, res) ->
        should.not.exist err
        should.exist res
        res.status.should.equal(-1)

        should.exist res.error
        
        res.error.user_id.should.include("PATTERN")

        res.error.email.should.include("LENGTH")
        res.error.email.should.include("PATTERN")

        res.error.password.should.include("LENGTH")
        res.error.password.should.include("CAPITAL")
        res.error.password.should.include("LOWERCASE")
        res.error.password.should.include("SAME_AS_USER_ID")

        res.error.locale.should.include("LANG")
        res.error.locale.should.include("SCRIPT")
        res.error.locale.should.include("REGION")

        res.error.data_zone.should.include("UNSUPPORTED")

        done()

    it 'Delete', (done) -> 
      Accounts.delete TestUserObject.user_id, (err, res) ->
        should.not.exist err
        (res in [0, 1]).should.be.true
        done()

    it 'Should be success', (done) -> 
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

    it 'Unique test = should be false', (done) ->
      user_object = 
        user_id: TestUserObject.user_id
        email: TestUserObject.email

      Accounts.unique user_object, (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        
        should.exist res.result
        res.result.should.eql
          user_id:
            name: user_object.user_id
            unique: false
          email:
            name: user_object.email
            unique: false

        done()

  describe '#renewTokens', () ->
    it 'Should be success', (done) ->
      userObject = 
        id   : TestUserObject.user_id
        password  : TestUserObject.password

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err
        res.should.have.property('result')
        res.result.should.have.property('access_token')
        res.result.should.have.property('token_type')
        res.result.should.have.property('expires_in')
        res.result.should.have.property('refresh_token')

        console.log ''
        console.log "\t#{userObject.user_id}/tern_iPhone/access_token:\t#{res.result.access_token}"
        console.log "\t#{userObject.user_id}/tern_iPhone/refresh_token:\t#{res.result.refresh_token}"

        done()

    it 'Bad id - status = -1', (done) ->
      userObject = 
        id   : ''
        password  : TestUserObject.password

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err

        res.should.eql
          status: -1
          error: 
            user_id: [ 'LENGTH', 'PATTERN' ]
        done()

    it 'Invalid email - status = -4', (done) ->
      userObject = 
        id   : 'xxxx@xxxx.xxx.xxx'
        password  : TestUserObject.password

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err

        res.should.eql
          status: -4
        done()

    it 'Email not verified - status = -4', (done) ->
      userObject = 
        id   : TestUserObject.email
        password  : TestUserObject.password

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err

        res.should.eql
          status: -7
        done()

    it 'Make email verified manually', (done) ->
      accountDB = DB.getDB 'accountDB'
      userKey = 'users/' + TestUserObject.user_id

      accountDB.hset userKey, 'email_verified', 'true', (err, res) ->
        should.not.exist err
        res.should.equal(1)
        done()

    it 'Should be success with email', (done) ->
      userObject = 
        id        : TestUserObject.email
        password  : TestUserObject.password

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err
        res.should.have.property('result')
        res.result.should.have.property('access_token')
        res.result.should.have.property('token_type')
        res.result.should.have.property('expires_in')
        res.result.should.have.property('refresh_token')

        console.log ''
        console.log "\t#{res.result.user_id}/tern_iPhone/access_token:\t#{res.result.access_token}"
        console.log "\t#{res.result.user_id}/tern_iPhone/refresh_token:\t#{res.result.refresh_token}"

        done()

    it 'Invalid user_id - status = -4', (done) ->
      userObject = 
        id   : 'INVALID_USER_ID'
        password  : TestUserObject.password

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err
        res.should.have.property('status')
        res.status.should.equal(-4)
        
        done()

    it 'Authentication failed - status = -4', (done) ->
      userObject = 
        id   : TestUserObject.user_id
        password  : 'BAD_PASSWORD'

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err
        res.should.have.property('status')
        res.status.should.equal(-4)
        
        done()

    it 'Bad arguments - status = -1', (done) ->
      userObject = {}

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err
        res.should.have.property('status')
        res.status.should.equal(-1)

        res.should.have.property('error')
        res.error.should.have.property('id')
        res.error.should.have.property('password')
        
        done()

  describe '#Delete again', () ->
    it 'success', (done) -> 
      Accounts.delete TestUserObject.user_id, (err, res) ->
        should.not.exist err
        res.should.equal(1)
        done()

  describe '#unique', () ->
    it "Null user_object: should be -1 and user_id: '[REQUIRED_EITHER:user_id:email]'", (done) -> 
      user_object = null

      Accounts.unique user_object, (err, res) ->
        ###
        res = 
          status: -1,
          error: 
            user_id: '[REQUIRED_EITHER:user_id:email]'
        ###
        should.not.exist err
        res.status.should.equal(-1)
        should.exist res.error
        should.exist res.error.user_id
        res.error.user_id.should.equal '[REQUIRED_EITHER:user_id:email]'
        done()

    it "No user_id neither email: should be -1 and user_id: '[REQUIRED_EITHER:user_id:email]'", (done) -> 
      user_object = {}

      Accounts.unique user_object, (err, res) ->
        ###
        res = 
          status: -1,
          error: 
            user_id: '[REQUIRED_EITHER:user_id:email]'
        ###
        should.not.exist err
        res.status.should.equal(-1)
        should.exist res.error
        should.exist res.error.user_id
        res.error.user_id.should.equal '[REQUIRED_EITHER:user_id:email]'
        done()

    it 'invalid user_id and email', (done) -> 
      user_object = 
        user_id: ''
        email: 'bad email'

      Accounts.unique user_object, (err, res) ->
        should.not.exist err
        res.should.eql
          status: -1
          error:
            user_id: ['LENGTH', 'PATTERN']
            email: [ 'PATTERN' ]

        done()

    it 'invalid user_id', (done) -> 
      user_object = 
        user_id: 'BadUserID'

      Accounts.unique user_object, (err, res) ->
        should.not.exist err
        res.should.eql
          status: -1
          error: 
            user_id: [ 'PATTERN' ]

        done()

    it 'invalid email', (done) -> 
      user_object = 
        email: 'bad email'

      Accounts.unique user_object, (err, res) ->
        should.not.exist err
        res.should.eql
          status: -1
          error: 
            email: [ 'PATTERN' ]

        done()

    it 'user_id is unique', (done) -> 
      user_object = 
        user_id: 'xxxxxxxxxxxxxx'

      Accounts.unique user_object, (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        should.exist res.result
        res.result.should.eql 
          user_id: 
            name: user_object.user_id
            unique: true
        done()

    it 'email is unique', (done) -> 
      user_object = 
        email: 'xxxxxxxxxxxxxx@xxxxxxx.xxxxx.xxx'

      Accounts.unique user_object, (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        should.exist res.result
        res.result.should.eql 
          email: 
            name: user_object.email
            unique: true
        done()

  describe '#Create a persistent test user', () ->

    writeTokenToFile = (user_object, client_id, tokens, next) ->

      console.log "\t#{user_object.user_id}/#{client_id}/access_token:\t#{tokens.access_token}"
      console.log "\t#{user_object.user_id}/#{client_id}/refresh_token:\t#{tokens.refresh_token}"

      # Write to file for another scripts access
      fileObj = 
        user_id       : user_object.user_id
        access_token  : tokens.access_token
        refresh_token : tokens.refresh_token

      fs.writeFile './test_user.json', JSON.stringify(fileObj), (err) ->
        should.not.exist err
        next()

    it 'tern_test_persistent', (done) -> 
      user_object = 
        user_id   : 'tern_test_persistent'
        email     : 'tern_test_persistent@tern.im'
        password  : '1Nick1'
        locale    : 'zh-Hans-CN'
        data_zone : 'beijing'
        
      client_id = "tern_iPhone"
      Accounts.unique user_id: user_object.user_id, (err, res) ->
        if res.result.user_id.unique is true
          Accounts.signup client_id, user_object, (err, res) ->
            should.not.exist err

            console.log "Sign_up: #{user_object.user_id}"
            writeTokenToFile user_object, client_id, res.result, done
        else
          Accounts.renewTokens client_id, { id: user_object.user_id, password: user_object.password }, (err, res) ->
            should.not.exist err

            console.log "renewTokens: #{user_object.user_id}"
            writeTokenToFile user_object, client_id, res.result, done