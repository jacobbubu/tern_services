should        = require 'should'
DeepLog       = require 'util'
BrokersHelper = require('tern.central_config').BrokersHelper
Subs          = null

describe 'Subscription Unit Test', () ->

  #userDB = DB.getDB 'UserDataDB'

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        Subs = require '../lib/models/subscription_mod'
        done()

  describe '#Subscribe Params Checking', () ->
    it "all params check", (done) ->

      tern = 
        user_id: 'tern_test_persistent'
        device_id: 'fake_device1'

      request =
        _tern: tern
        data: {
          win_size: 1000
          folders: {
            'unknown_folder': {
              win_size: 2000
              min_ts: '-sss'
            }
            'memos': {
              win_size: 2000
              max_ts: '-aaa'
            }
          }
        }

      connection = 
        _tern: tern

      Subs.subscribe request, connection, (err, res) ->        
        should.not.exist err
        res.status.should.equal(-1)
        error = res.error
        should.exist error
        error.win_size.should.eql(['RANGE:1:500'])
        error['folders[unknown_folder]'].should.eql(['UNSUPPORTED'])
        error['folders[unknown_folder].win_size'].should.eql(['RANGE:1:500'])
        error['folders[unknown_folder].min_ts'].should.eql(['STRING_INTEGER'])
        error['folders[unknown_folder].max_ts'].should.eql(['REQUIRED'])
        error['folders[memos].win_size'].should.eql(['RANGE:1:500'])
        error['folders[memos].min_ts'].should.eql(['REQUIRED'])
        error['folders[memos].max_ts'].should.eql(['STRING_INTEGER'])        
        done()

    it "data is not an object", (done) ->

      tern = 
        user_id: 'tern_test_persistent'
        device_id: 'fake_device1'

      request =
        _tern: tern
        data: 1

      connection = 
        _tern: tern

      Subs.subscribe request, connection, (err, res) -> 
        should.not.exist err
        res.status.should.equal(-1)
        error = res.error
        should.exist error
        error.data.should.eql(['OBJECT'])
        done()

    it "data does not exist", (done) ->

      tern = 
        user_id: 'tern_test_persistent'
        device_id: 'fake_device1'

      request =
        _tern: tern

      connection = 
        _tern: tern

      Subs.subscribe request, connection, (err, res) ->
        should.not.exist err
        res.status.should.equal(-1)
        error = res.error
        should.exist error
        error.data.should.eql(['REQUIRED'])
        done()

    ###
    it "success", (done) ->

      tern = 
        user_id: 'tern_test_persistent'
        device_id: 'fake_device1'

      request =
        _tern: tern
        data: {
          win_size: 200
          folders: {
            'memos': {
              win_size: 150
              min_ts: '-inf'
              max_ts: '+inf'
            }
            'tags': {
              win_size: 150
              min_ts: '133567777'
              max_ts: '133567779'
            }
          }
        }

      connection = 
        _tern: tern

      Subs.subscribe request, connection, (err, res) ->        
        should.not.exist err
        res.status.should.equal(0)
        done()
    ###
