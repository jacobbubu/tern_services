should      = require 'should'
spawn       = (require 'child_process').spawn
path        = require 'path'
Async       = require "async"
Log         = require './test_log'
Accounts    = require '../models/account_mod'

WebSocketClient = require('websocket').client
main = path.resolve __dirname, '../index.coffee'
authServer = null

methodTest = (sendFn, recvFn, closeFn) ->
  client = new WebSocketClient()

  client.on 'connectFailed', (error) ->
    throw new Error("Connection error unexpectly. #{error.toString()}")

  client.on 'connect', (connection) ->

    if sendFn?
      sendFn connection

    connection.on 'message', (message) ->
      if recvFn?
        recvFn message

    connection.on 'close', (reasonCode, description)-> 
      if authServer?
        if closeFn?
          closeFn reasonCode, description
        else
          Log.clientError "Connection closed unexpectly. #{reasonCode}: #{description}"

  options = 
    'authorization'     : "Client, client_id = tern_iPhone;client_secret =Ob-Kp_rWpnHbQ0h059uvJX"
    'accept-language'   : 'zh'
    'x-device-id'       : 'device1'
    'x-compress-method' : 'lzf'

  client.connect 'ws://localhost:8080/1/websocket'
    , 'auth'
    , null
    , options

describe 'WebSocket Server Unit Test', () ->
    
  describe '#Start Auth. Server', () ->
    it "Should be success", (done) ->
      authServer = spawn 'coffee', [main]

      authServer.stdout.on 'data', (data) ->
        message = data.toString()

        Log.serverLog message

        if /Auth. Server is listening on port/i.test message
          done()

      authServer.stderr.on 'data', (data) ->
        message = data.toString()

        Log.serverError message

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

          connection.sendUTF JSON.stringify(req)

      , (message) ->
          response = JSON.parse message.utf8Data

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
          connection.sendUTF JSON.stringify(req)
      , null
      , (reasonCode, description) ->
        Log.clientLog reasonCode,description
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
          
          connection.sendUTF JSON.stringify(req)
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
          
          connection.sendUTF JSON.stringify(req)
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
          
          connection.sendUTF JSON.stringify(req)
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
          
          connection.sendUTF JSON.stringify(req)
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
          
          connection.sendUTF JSON.stringify(req)
      , (message) ->
          response = JSON.parse message.utf8Data

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
          
          connection.sendUTF JSON.stringify(req)
      , (message) ->
          response = JSON.parse message.utf8Data

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

          connection.sendUTF JSON.stringify(req)

      , (message) ->
          response = JSON.parse message.utf8Data

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

          connection.sendUTF JSON.stringify(req)

      , (message) ->
          response = JSON.parse message.utf8Data

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

          connection.sendUTF JSON.stringify(req)

      , (message) ->
          response = JSON.parse message.utf8Data

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

  describe '#Kill Service', () ->
    it "SIGINT", (done) ->
      if authServer?
        authServer.kill 'SIGINT'
        authServer = null

      done()

  ###
  describe '#timeout 2s', () ->
    it "2s wait", (done) ->
      setTimeout done, 2000
      done()
  ###