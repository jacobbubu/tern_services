should  = require 'should'
IPToDataZone  = require '../lib/ip_to_datazone'

describe 'IP To DataZone Unit Test', () ->
  
  describe '#IP Lookup', () ->
    it "beijing ip: 124.205.162.210", (done) ->
      IPToDataZone.lookup '124.205.162.210', (err, data_zone) ->
        should.not.exist err
        data_zone.should.equal('beijing')
        done()

    it "nanjing ip: 58.213.35.33", (done) ->
      IPToDataZone.lookup '124.205.162.210', (err, data_zone) ->
        should.not.exist err
        data_zone.should.equal('beijing')
        done()

    it "gb ip: 178.79.131.110", (done) ->
      IPToDataZone.lookup '178.79.131.110', (err, data_zone) ->
        should.not.exist err
        data_zone.should.equal('ireland')
        done()

    it "zz ip: 1.255.255.4", (done) ->
      IPToDataZone.lookup '1.255.255.4', (err, data_zone) ->
        should.not.exist err
        data_zone.should.equal('virginia')
        done()

  describe 'Internal IP', () ->

    it "192.168.1.1", (done) ->
      IPToDataZone.isInternalIP('192.168.1.1').should.be.true
      done()

    it "172.31.1.1", (done) ->
      IPToDataZone.isInternalIP('172.31.1.1').should.be.true
      done()

    it "10.10.10.10", (done) ->
      IPToDataZone.isInternalIP('10.10.10.10').should.be.true
      done()

    it "178.79.131.110", (done) ->
      IPToDataZone.isInternalIP('178.79.131.110').should.be.false
      done()

  describe 'Loopback IP', () ->
    it "127.0.0.1", (done) ->
      IPToDataZone.isLoopbackIP('127.0.0.1').should.be.true
      done()

    it "178.79.131.110", (done) ->
      IPToDataZone.isLoopbackIP('178.79.131.110').should.be.false
      done()
