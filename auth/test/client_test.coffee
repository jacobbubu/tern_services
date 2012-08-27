should  = require 'should'
BrokersHelper = require('tern.central_config').BrokersHelper

Clients = null

describe 'Client Unit Test', () ->

describe '#Init config brokers', () ->
  it "Init", (done) ->
    BrokersHelper.init ->
      Clients = require '../lib/models/client_mod'
      done()

  describe '#Stocked_Clients', () ->
    it "Clear/Populate", (done) ->

      Clients.clearAll (err, res) ->
        Clients.populate (err, res) ->
          should.not.exist err
          res.should.be.an.instanceof(Array)          
          res.should.eql([false, false, false, false, false])
          done()

  describe '#Authenticate', () ->
    it "Success", (done) ->

      Clients.authenticate "tern_iPhone", "Ob-Kp_rWpnHbQ0h059uvJX", (err, res) ->
        should.not.exist err
        res.should.eql(true)
        done()

    it "Failed1-Bad Client_ID", (done) ->

      Clients.authenticate "BAD_CLIENT_ID", "Ob-Kp_rWpnHbQ0h059uvJX", (err, res) ->
        should.not.exist err
        res.should.eql(false)
        done()

    it "Failed-Bad Secret", (done) ->

      Clients.authenticate "tern_iPhone", "BAD_SECRET", (err, res) ->
        should.not.exist err
        res.should.eql(false)
        done()

  describe '#Lookup', () ->

    it "Success", (done) ->
      Clients.lookup "tern_iPhone", (err, res) ->
        should.not.exist err
        res.should.have.property('client_id')
        res.should.have.property('secret')
        res.should.have.property('grant_type')
        res.should.have.property('ttl')
        res.should.have.property('pre_defined')
        res.should.have.property('scope')
        done()

    it "Failed1-Bad Client_ID", (done) ->
      Clients.lookup "BAD_CLIENT_ID", (err, res) ->
        should.not.exist err
        should.not.exist res
        done()

  describe '#Suspend/Resume', () ->
    it "Success-resume-suspend", (done) ->
      Clients.resume "tern_iPhone", (err, res) ->
        should.not.exist err

        Clients.suspend "tern_iPhone", (err, res) ->
          should.not.exist err
          res.should.equal('0')
          done()

    it "Success-suspend-resume", (done) ->
      Clients.suspend "tern_iPhone", (err, res) ->
        should.not.exist err

        Clients.resume "tern_iPhone", (err, res) ->
          should.not.exist err
          res.should.equal('1')
          done()

    it "Failed1-Bad Client_ID", (done) ->
      Clients.suspend "BAD_CLIENT_ID", (err, res) ->
        should.not.exist err
        should.not.exist res
        done()