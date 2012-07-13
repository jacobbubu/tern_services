should      = require 'should'
DB          = require('ternlibs').database
Accounts    = require '../models/account_mod'
fs          = require 'fs'

describe 'Account_mod Test', () ->

  describe '#signup', () ->

    it 'BAD USER_ID/PASSWORD/DATA_ZONE/LOCALE, SAME_AS_USER_ID', (done) -> 

      user_object = 
        user_id   : '__'
        password  : '__'
        locale    : 'UNKNOWN-BADSCRIPT-LOCALE'
        data_zone : 'BAD_DATA_ZONE'

      Accounts.signup "tern_iPhone", user_object, (err, res) ->
        should.not.exist err
        should.exist res
        res.status.should.equal(-1)

        should.exist res.error
        
        res.error.user_id.should.include("LENGTH")
        res.error.user_id.should.include("PATTERN")

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
      Accounts.delete 'tern_test_user_01', (err, res) ->
        should.not.exist err
        (res in [0, 1]).should.be.true
        done()

    it 'Should be success', (done) -> 
      user_object = 
        user_id   : 'tern_test_user_01'
        password  : '1Nick1'
        locale    : 'zh-Hans-CN'
        data_zone : 'beijing'
        
      Accounts.signup "tern_iPhone", user_object, (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        
        res.should.have.property('result')
        res.result.should.have.property('access_token')
        res.result.should.have.property('token_type')
        res.result.should.have.property('expires_in')
        res.result.should.have.property('refresh_token')

        console.log ''
        console.log "\ttern_test_user_01/tern_iPhone/access_token:\t#{res.result.access_token}"
        console.log "\ttern_test_user_01/tern_iPhone/refresh_token:\t#{res.result.refresh_token}"

        accountDB = DB.getDB 'AccountDB'
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
      Accounts.unique 'tern_test_user_01', (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        res.result.should.be.false
        done()

  describe '#renewTokens', () ->
    it 'Should be success', (done) ->
      userObject = 
        user_id   : 'tern_test_user_01'
        password  : '1Nick1'

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err
        res.should.have.property('result')
        res.result.should.have.property('access_token')
        res.result.should.have.property('token_type')
        res.result.should.have.property('expires_in')
        res.result.should.have.property('refresh_token')

        console.log ''
        console.log "\ttern_test_user_01/tern_iPhone/access_token:\t#{res.result.access_token}"
        console.log "\ttern_test_user_01/tern_iPhone/refresh_token:\t#{res.result.refresh_token}"

        done()

    it 'Invalid user_id - status = -4', (done) ->
      userObject = 
        user_id   : 'INVALID_USER_ID'
        password  : '1Nick1'

      Accounts.renewTokens 'tern_iPhone', userObject, (err, res) ->
        should.not.exist err
        res.should.have.property('status')
        res.status.should.equal(-4)
        
        done()

    it 'Authentication failed - status = -4', (done) ->
      userObject = 
        user_id   : 'tern_test_user_01'
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
        res.error.should.have.property('user_id')
        res.error.should.have.property('password')
        
        done()

  describe '#Delete again', () ->
    it 'success', (done) -> 
      Accounts.delete 'tern_test_user_01', (err, res) ->
        should.not.exist err
        res.should.equal(1)
        done()

  describe '#unique', () ->
    it 'should be true', (done) -> 
      Accounts.unique 'xxxxxxxxxxxxx', (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        res.result.should.be.true
        done()

    it 'should be false', (done) -> 
      Accounts.unique '', (err, res) ->
        should.not.exist err
        res.status.should.equal(0)
        res.result.should.be.false
        done()

  describe '#Create a persistent test user', () ->
    it 'tern_test_persistent', (done) -> 
      user_object = 
        user_id   : 'tern_test_persistent'
        password  : '1Nick1'
        locale    : 'zh-Hans-CN'
        data_zone : 'beijing'
        
      client_id = "tern_iPhone"
      Accounts.unique user_object.user_id, (err, res) ->
        if res.result is true
          Accounts.signup client_id, user_object, (err, res) ->
            should.not.exist err

            console.log "Sign_up: #{user_object.user_id}"
            console.log "\t#{user_object.user_id}/#{client_id}/access_token:\t#{res.result.access_token}"
            console.log "\t#{user_object.user_id}/#{client_id}/refresh_token:\t#{res.result.refresh_token}"

            # Write to file for another scripts access
            fileObj = 
              user_id       : user_object.user_id
              access_token  : res.result.access_token
              refresh_token : res.result.refresh_token

            fs.writeFile './test_user.json', JSON.stringify(fileObj), (err) ->
              console.log err
              should.not.exist err
              done()
        else
          done()


