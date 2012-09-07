Path            = require 'path'
should          = require 'should'
Async           = require "async"
WebSocketClient = require('websocket').client
BrokersHelper   = require('tern.central_config').BrokersHelper

WSMessageHelper = null
SpawnServerTest = null
Log             = null
Accounts        = null
DB              = null

serverPath = Path.resolve __dirname, '../lib/index.js'

TestUserObject = 
  user_id   : 'tern_test_user_01'
  email     : 'tern_test_user_01@tern.im'
  password  : '1Nick1'
  locale    : 'zh-Hans-CN'
  data_zone : 'beijing'

oldAccessToken  = null
oldRefreshToken = null

methodTest = (sendFn, recvFn, closeFn) ->
  client = new WebSocketClient()

  client.on 'connectFailed', (error) ->
    throw new Error("Connection error unexpectly. #{error.toString()}")

  client.on 'connect', (connection) ->

    if sendFn?
      sendFn connection

    connection.on 'message', (message) ->
      if recvFn?
        recvFn JSON.parse WSMessageHelper.parse(message)

    connection.on 'close', (reasonCode, description)-> 

      #if SpawnServerTest.serverProcess()?
      if closeFn?
        closeFn reasonCode, description
      else
        Log.clientError "Connection closed unexpectly. #{reasonCode}: #{description}"

  options = 
    'authorization'     : "Client, client_id = tern_iPhone;client_secret =Ob-Kp_rWpnHbQ0h059uvJX"
    'accept-language'   : 'zh'
    'x-device-id'       : 'device1'
    'x-compress-method' : 'lzf'

  { host, port } = BrokersHelper.getConfig('centralAuth/websocket/connect').value
  endpoint = "ws://#{host}:#{port}/1/websocket"

  client.connect endpoint
    , 'auth'
    , null
    , options

describe 'WebSocket Server Unit Test', () ->

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        DB              = require('tern.database')
        WSMessageHelper = require('tern.ws_message_helper')
        SpawnServerTest = require('tern.test_utils').spawn_server
        Log             = require('tern.test_utils').test_log        
        Accounts        = require '../lib/models/account_mod'
        done()

  describe.skip '#Start Auth. Server', () ->
    it "Spawn Server Process", (done) ->
      SpawnServerTest.start serverPath, /Auth. Web Socket Server is listening on/i, () ->
        done()

  describe '#Unique', () ->

    it "Delete #{TestUserObject.user_id}", (done) -> 
      Accounts.delete TestUserObject.user_id, (err, deleted) ->
        should.not.exist err
        console.log "#{deleted} user deleted"
        done()

    it "User ID unique - should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.unique'
              data:
                user_id: TestUserObject.user_id
          WSMessageHelper.send connection, JSON.stringify(req)

        , (response) ->

          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.unique')

          response.response.should.have.property('req_ts')
          response.response.should.have.property('result')

          result = response.response.result
          result.should.eql 
            user_id:
              name: TestUserObject.user_id
              unique: true
          done()
      )

    it "Email unique - should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.unique'
              data:
                email: TestUserObject.email
          WSMessageHelper.send connection, JSON.stringify(req)

        , (response) ->

          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.unique')

          response.response.should.have.property('req_ts')
          response.response.should.have.property('result')

          result = response.response.result
          result.should.eql 
            email:
              name: TestUserObject.email
              unique: true
          done()
      )

    it "Should be failed: Request = {}", (done) ->
      methodTest(
        (connection) ->
          req = {}
          WSMessageHelper.send connection, JSON.stringify(req)
      , null
      , (reasonCode, description) ->
        Log.clientLog reasonCode, description
        reasonCode.should.equal(1007)
        done()
      )

    it "Should be failed: without request property", (done) ->
      methodTest(
        (connection) ->
          req = 
            method: 'auth.unique'
            data:
              user_id: 'tern_test_user_01'
          
          WSMessageHelper.send connection, JSON.stringify(req)
      , null
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        reasonCode.should.equal(1007)
        done()
      )
    it "Should be failed: without req_ts property", (done) ->
      methodTest(
        (connection) ->
          req = 
            request:
              method: 'auth.unique'
              data:
                user_id: 'tern_test_user_01'
          
          WSMessageHelper.send connection, JSON.stringify(req)
      , null
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        reasonCode.should.equal(1007)
        done()
      )
    it "Should be failed: without method property", (done) ->
      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              data:
                user_id: 'tern_test_user_01'
          
          WSMessageHelper.send connection, JSON.stringify(req)
      , null
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        reasonCode.should.equal(1007)
        done()
      )      
    it "Should be failed: without data", (done) ->
      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.unique'
          
          WSMessageHelper.send connection, JSON.stringify(req)
      , null
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        reasonCode.should.equal(1007)
        done()
      )

    it "Should be success: without user_id (data: '')", (done) ->
      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.unique'
              data: ''
          
          WSMessageHelper.send connection, JSON.stringify(req)
      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(-1)
          response.response.method.should.equal('auth.unique')

          response.response.should.have.property('req_ts')
          response.response.should.have.property('error')

          error = response.response.error
          error.should.eql 
            user_id: '[REQUIRED_EITHER:user_id:email]'
          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error("Should not be here")
      )

    it "Should be success: user_id type conversion", (done) ->
      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.unique'
              data:
                user_id: 1234  #Should be string
          
          WSMessageHelper.send connection, JSON.stringify(req)
      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.unique')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')
          
          result = response.response.result
          result.should.eql
            user_id: 
              name: '1234'
              unique: true

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error("Should not be here")
      )
  
  describe '#Signup', () ->

    it "Signup should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.signup'
              data: TestUserObject

          WSMessageHelper.send connection, JSON.stringify(req)

      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.signup')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')

          result = response.response.result
          result.should.have.property('user_id')
          result.should.have.property('access_token')
          result.should.have.property('token_type')
          result.should.have.property('expires_in')
          result.should.have.property('refresh_token')
          
          oldAccessToken  = result.access_token
          oldRefreshToken = result.refresh_token

          Log.clientLog ""
          Log.clientLog "\t#{result.user_id}/tern_iPhone/access_token:\t#{result.access_token}"
          Log.clientLog "\t#{result.user_id}/tern_iPhone/refresh_token:\t#{result.refresh_token}"

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error(description)
      )

  describe '#Refresh', () ->

    it "Refresh Token should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.refreshToken'
              data:
                refresh_token   : oldRefreshToken

          WSMessageHelper.send connection, JSON.stringify(req)

      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.refreshToken')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')

          result = response.response.result
          result.should.have.property('access_token')
          result.should.have.property('token_type')
          result.should.have.property('expires_in')
          result.should.have.property('refresh_token')
          
          result.access_token.should.not.equal(oldAccessToken)
          result.refresh_token.should.equal(oldRefreshToken)

          Log.clientLog ""
          Log.clientLog "\t#{TestUserObject.user_id}/tern_iPhone/access_token:\t#{result.access_token}"
          Log.clientLog "\t#{TestUserObject.user_id}/tern_iPhone/refresh_token:\t#{result.refresh_token}"

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode, description
        throw new Error(description)
      )

  describe '#Renew', () ->

    it "With user_id should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.renewTokens'
              data:
                id   : TestUserObject.user_id
                password  : TestUserObject.password

          WSMessageHelper.send connection, JSON.stringify(req)

      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.renewTokens')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')

          result = response.response.result
          result.should.have.property('user_id')
          result.should.have.property('access_token')
          result.should.have.property('token_type')
          result.should.have.property('expires_in')
          result.should.have.property('refresh_token')
          
          Log.clientLog ""
          Log.clientLog "\t#{result.user_id}/tern_iPhone/access_token:\t#{result.access_token}"
          Log.clientLog "\t#{result.user_id}/tern_iPhone/refresh_token:\t#{result.refresh_token}"

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error(description)
      )

    it 'Make email verified manually', (done) ->
      accountDB = DB.getDB 'accountDB'
      userKey = 'users/' + TestUserObject.user_id

      accountDB.hset userKey, 'email_verified', 'true', (err, res) ->
        should.not.exist err
        res.should.equal(1)
        done()

    it "With email should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.renewTokens'
              data:
                id   : TestUserObject.email
                password  : TestUserObject.password

          WSMessageHelper.send connection, JSON.stringify(req)

      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.renewTokens')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')

          result = response.response.result
          result.should.have.property('user_id')
          result.should.have.property('access_token')
          result.should.have.property('token_type')
          result.should.have.property('expires_in')
          result.should.have.property('refresh_token')
          
          Log.clientLog ""
          Log.clientLog "\t#{result.user_id}/tern_iPhone/access_token:\t#{result.access_token}"
          Log.clientLog "\t#{result.user_id}/tern_iPhone/refresh_token:\t#{result.refresh_token}"

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error(description)
      )

  describe '#Delete user again', () ->
    it "Delete #{TestUserObject.user_id}", (done) -> 
      Accounts.delete TestUserObject.user_id, (err, deleted) ->
        should.not.exist err
        console.log "#{deleted} user deleted"
        done()

  describe.skip '#Stop Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()