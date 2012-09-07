should          = require 'should'
Path            = require 'path'
BrokersHelper   = require('tern.central_config').BrokersHelper

TernClient      = require './tern_client'
TestData        = require './test_data'
Log             = null
SpawnServerTest = null

serverPath = Path.resolve __dirname, '../lib/index.js'
ternClient = null

pushHandler = (message) ->
  strOutput = ("#{fName}:#{f.changelog.length}:#{f.has_more}" for fName, f of message.data.folders)  
  Log.clientLog "Push: " + strOutput

describe 'Data WebSocket Server Unit Test', () ->
    
  data = null

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        Log             = require('tern.test_utils').test_log
        #SpawnServerTest = require('tern.test_utils').spawn_server
        done()  

  describe.skip '#Start Data Server', () ->
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

    it "Delay 0.5s", (done) ->

      setTimeout ->
        done()
      , 500

    it "Get", (done) ->
      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'data.subscription.get'
          data: {}

      ternClient.send req, (res) ->

        expected = 
          win_size: 10
          folders: {}

        #Log.clientDir res, 4
        res.should.have.property('status')
        res.status.should.equal(0)
        res.should.have.property('result')
        res.result.should.eql expected
        done()

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

  describe '#Media server host', () ->
    it "Get host", (done) ->
      req = 
        request:
          req_ts: (+new Date).toString()
          method: 'media.host.get'
          data: {}        

      ternClient.send req, (res) ->
        res.should.have.property('status')
        res.status.should.equal(0)
        done()


  describe '#Close', () ->
    it "Close", (done) ->
      ternClient.close ->
        done()

  describe.skip '#Stop Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()




