should          = require 'should'
TestData        = require './test_data'
Log             = require('ternlibs').test_log
Path            = require 'path'
TernClient      = require './tern_client'
SpawnServerTest = require('ternlibs').spawn_server_test

serverPath = Path.resolve __dirname, '../ws_server.coffee'
ternClient = null

pushHandler = (message) ->
  strOutput = ("#{fName}:#{f.changelog.length}:#{f.has_more}" for fName, f of message.data.folders)  
  Log.clientLog "Push: " + strOutput

describe 'Data WebSocket Server Unit Test', () ->
    
  data = null

  describe '#Start Data Server', () ->
    it "Spawn Server Process", (done) ->
      SpawnServerTest.start serverPath, /Data WebSocket Server is listening on/i, () ->
        done()

  describe '#Connect', () ->
    it "Connection", (done) ->
      ternClient = new TernClient
      ternClient.connect () ->
        ternClient.pushHandler = pushHandler
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

      ternClient.send req, (res) ->        
        res.should.have.property('status')
        res.status.should.equal(0)
        done()

    it "Get", (done) ->
      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.get'
          data: {}

      ternClient.send req, (res) ->

        #Log.clientDir res, 4
        res.should.have.property('status')
        res.status.should.equal(0)
        res.should.have.property('result')
        res.result.should.eql(data)
        done()

    it "Delay 1s", (done) ->

      setTimeout ->
        done()
      , 1000

    it "Unubscribe", (done) ->

      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.unsubscribe'
          data: ['memos']

      ternClient.send req, (res) ->
        res.should.have.property('status')
        res.status.should.equal(0)
        done()

    it "Get again", (done) ->
      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.get'
          data: {}

      ternClient.send req, (res) ->

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
      ternClient.close ->
        done()

  describe '#Kill Service', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()




