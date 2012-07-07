should  = require 'should'
Consts  = require '../consts/consts'

describe 'Consts Unit Test', () ->
  
  describe '#lang_scripts', () ->
    it "lang_scripts", (done) ->
      Consts.lang_scripts.hans.should.equal(501)
      done()

  describe '#languages', () ->
    it "languages", (done) ->
      Consts.languages.zh.should.equal('Chinese')
      done()

  describe '#countries', () ->
    it "countries", (done) ->
      Consts.countries.CN.should.equal('China')
      done()

  describe '#country_info', () ->
    it "country_info", (done) ->
      Consts.country_info.CN.currency.should.equal('CNY')
      done()

  describe '#locale', () ->
    it "locale", (done) ->
      Consts.locales["zh-Hans-HK"].should.equal("Chinese (Simplified Han Hong Kong SAR China)")
      done()

  describe '#data_zones', () ->
    it "data_zones", (done) ->
      Consts.data_zones["beijing"]["country"].should.equal("CN")
      done()
