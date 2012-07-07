should          = require 'should'
WebSocketClient = require('websocket').client
TestData        = require './test_data'
Log             = require './test_log'
path            = require 'path'
spawn           = (require 'child_process').spawn
TernClient      = require './tern_client'

WebSocketClient = require('websocket').client

internals = 
  main: path.resolve __dirname, '../ws_server.coffee'
  dataWSServer: null
  ternClient: null

  waitForOutput: (pattern, done) ->

    stdoutCallback = (data) ->
      message = data.toString()
      if pattern.test message
        internals.dataWSServer.stdout.removeListener 'data', stdoutCallback
        internals.dataWSServer.stderr.removeListener 'data', stderrCallback
        done()

    stderrCallback = (data) ->
      message = data.toString()
      if pattern.test message
        internals.dataWSServer.stdout.removeListener 'data', stdoutCallback
        internals.dataWSServer.stderr.removeListener 'data', stderrCallback
        done()

    internals.dataWSServer.stdout.on 'data', stdoutCallback
    internals.dataWSServer.stderr.on 'data', stderrCallback

  stdoutCallback: (data) ->
    message = data.toString()
    Log.serverLog message

  stderrCallback: (data) ->
    message = data.toString()
    Log.serverError message

  startOutputMon: () ->
    internals.dataWSServer.stdout.on 'data', internals.stdoutCallback
    internals.dataWSServer.stderr.on 'data', internals.stderrCallback

  stopOutputMon: () ->
    internals.dataWSServer.stdout.on 'data', internals.stdoutCallback
    internals.dataWSServer.stderr.on 'data', internals.stderrCallback

  pushHandler: (message) ->
    strOutput = ("#{fName}:#{f.changelog.length}:#{f.has_more}" for fName, f of message.data.folders)  
    Log.clientLog "Push: " + strOutput

describe 'Data WebSocket Server Unit Test', () ->
    
  data = null

  describe '#Start Data Server', () ->
    it "Spawn Server Process", (done) ->
      internals.dataWSServer = spawn 'coffee', [internals.main]
      internals.startOutputMon()
      internals.waitForOutput /Data WebSocket Server is listening on port/i, done

  describe '#Connect', () ->
    it "Connection", (done) ->
      ternClient = new TernClient
      ternClient.connect () ->
        internals.ternClient = ternClient
        ternClient.pushHandler = internals.pushHandler
        done()

  describe '#Subscription', () ->
    it "Subscribe", (done) ->

      data = 
        win_size: 10
        folders: 
          'memos':
            win_size: 150
            min_ts: '-inf'
            max_ts: '+inf'
          'tags':
            win_size: 150
            min_ts: '-inf'
            max_ts: '+inf'

      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.subscribe'
          data: data

      internals.ternClient.send req, (res) ->        
        res.should.have.property('status')
        res.status.should.equal(0)
        done()

    it "Get", (done) ->
      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.get'
          data: {}

      internals.ternClient.send req, (res) ->

        #Log.clientDir res, 4
        res.should.have.property('status')
        res.status.should.equal(0)
        res.should.have.property('result')
        res.result.should.eql(data)
        done()

    it "Delay 3s", (done) ->

      setTimeout ->
        done()
      , 3000

    it "Unubscribe", (done) ->

      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.unsubscribe'
          data: ['memos']

      internals.ternClient.send req, (res) ->
        res.should.have.property('status')
        res.status.should.equal(0)
        done()

    it "Get again", (done) ->
      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.get'
          data: {}

      internals.ternClient.send req, (res) ->

        #Log.clientDir res, 4
        res.should.have.property('status')
        res.status.should.equal(0)
        res.should.have.property('result')
        ###
        temp =
          win_size: 200
          folders: 
            'tags':
              win_size: 150
              min_ts: '-inf'
              max_ts: '+inf'

        response.result.should.eql(temp)
        ###
        done()

  describe '#Close', () ->
    it "Close", (done) ->
      internals.ternClient.close ->
        done()

  describe '#Kill Service', () ->
    it "SIGINT", (done) ->
      internals.stopOutputMon()

      if internals.dataWSServer?
        internals.dataWSServer.kill 'SIGINT'
        internals.dataWSServer = null

      done()




