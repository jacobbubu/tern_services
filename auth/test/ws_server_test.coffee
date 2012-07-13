Log             = require('ternlibs').test_log
Path            = require 'path'
SpawnServerTest = require('ternlibs').spawn_server_test

should          = require 'should'

Async           = require "async"
Accounts        = require '../models/account_mod'
DefaultPorts    = require('ternlibs').default_ports
WSMessageHelper = require('ternlibs').ws_message_helper

WebSocketClient = require('websocket').client

serverPath = Path.resolve __dirname, '../index.coffee'

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

      if SpawnServerTest.serverProcess()?
        if closeFn?
          closeFn reasonCode, description
        else
          Log.clientError "Connection closed unexpectly. #{reasonCode}: #{description}"

  options = 
    'authorization'     : "Client, client_id = tern_iPhone;client_secret =Ob-Kp_rWpnHbQ0h059uvJX"
    'accept-language'   : 'zh'
    'x-device-id'       : 'device1'
    'x-compress-method' : 'lzf'

  client.connect DefaultPorts.CentralAuthWS.uri
    , 'auth'
    , null
    , options

describe 'WebSocket Server Unit Test', () ->
    
  describe '#Start Auth. Server', () ->
    it "Spawn Server Process", (done) ->
      SpawnServerTest.start serverPath, /Auth. Web Socket Server is listening on/i, () ->
        console.dir SpawnServerTest
        done()

  describe '#Unique', () ->
    it "Should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.unique'
              data:
                user_id: 'tern_test_user_01'

          WSMessageHelper.send connection, JSON.stringify(req)

      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.unique')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')
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
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.unique')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')
          response.response.result.should.equal(false)
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
          response.response.result.should.equal(true)
          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error("Should not be here")
      )
  
  describe '#Signup', () ->

    oldAccessToken  = null
    oldRefreshToken = null

    it "Delete 'tern_test_user_01'", (done) -> 
      Accounts.delete 'tern_test_user_01', (err, res) ->
        should.not.exist err
        done()

    it "Signup should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.signup'
              data:
                user_id   : 'tern_test_user_01'
                password  : '1Nick1'
                locale    : 'zh-Hans-CN'
                data_zone : 'beijing'

          WSMessageHelper.send connection, JSON.stringify(req)

      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.signup')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')

          result = response.response.result
          result.should.have.property('access_token')
          result.should.have.property('token_type')
          result.should.have.property('expires_in')
          result.should.have.property('refresh_token')
          
          oldAccessToken  = result.access_token
          oldRefreshToken = result.refresh_token

          Log.clientLog ""
          Log.clientLog "\ttern_test_user_01/tern_iPhone/access_token:\t#{result.access_token}"
          Log.clientLog "\ttern_test_user_01/tern_iPhone/refresh_token:\t#{result.refresh_token}"

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error(description)
      )

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
          Log.clientLog "\ttern_test_user_01/tern_iPhone/access_token:\t#{result.access_token}"
          Log.clientLog "\ttern_test_user_01/tern_iPhone/refresh_token:\t#{result.refresh_token}"

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode, description
        throw new Error(description)
      )

    it "Renew Tokens should be success", (done) ->

      methodTest(
        (connection) ->
          req = 
            request:
              req_ts: (+new Date).toString()
              method: 'auth.renewTokens'
              data:
                user_id   : 'tern_test_user_01'
                password  : '1Nick1'

          WSMessageHelper.send connection, JSON.stringify(req)

      , (response) ->
          response.should.have.property('response')
          response.response.should.have.property('status')
          response.response.status.should.equal(0)
          response.response.method.should.equal('auth.renewTokens')

          response.response.should.have.property('req_ts')

          response.response.should.have.property('result')

          result = response.response.result
          result.should.have.property('access_token')
          result.should.have.property('token_type')
          result.should.have.property('expires_in')
          result.should.have.property('refresh_token')
          
          Log.clientLog ""
          Log.clientLog "\ttern_test_user_01/tern_iPhone/access_token:\t#{result.access_token}"
          Log.clientLog "\ttern_test_user_01/tern_iPhone/refresh_token:\t#{result.refresh_token}"

          done()
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
        throw new Error(description)
      )

  describe '#Stop Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()
  ###
  describe '#timeout 2s', () ->
    it "2s wait", (done) ->
      setTimeout done, 2000
      done()
  ###