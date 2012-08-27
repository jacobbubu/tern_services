should        = require 'should'
BrokersHelper = require('tern.central_config').BrokersHelper
UserCounter   = null

describe 'UserCounter Unit Test', () ->

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        UserCounter = require '../lib/models/user_counter_mod'
        done()

  describe '#counter inc', () ->
    old_counter = 0

    it "getCurrent", (done) ->
      UserCounter.getCurrent 'tern_test_persistent', 'memo', (err, res) ->
        old_counter = res
        done()
    it "increase", (done) ->
      UserCounter.increase 'tern_test_persistent', 'memo', (err, res) ->
        res.should.equal(old_counter + 1)
        done()
    it "decrease", (done) ->
      UserCounter.decrease 'tern_test_persistent', 'memo', (err, res) ->
        res.should.equal(old_counter)
        done()

  describe 'unsupported folder', () ->
    it "folder_name = XXXXXXXX", (done) ->
      UserCounter.getCurrent 'tern_test_persistent', 'XXXXXXXX', (err, res) ->
        err.name.should.equal('ArgumentUnsupportedException')
        done()
