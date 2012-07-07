should  = require 'should'
Checker = require '../lib/param_checker'

describe 'Param_checker Unit Test', () ->
  
  describe '#keysCount', () ->
    it "null", (done) ->
      ( -> Checker.keysCount null ).should.throw()
      done()

    it "object={}", (done) ->
      o = {}
      Checker.keysCount(o).should.equal(0)
      done()

    it "object={ 'k1': 'v1' }", (done) ->
      o = { 'k1': 'v1' }
      Checker.keysCount(o).should.equal(1)
      done()

    it "number/string.func type", (done) ->
      o = 123
      ( -> Checker.keysCount o ).should.throw()
      o = 'hello'
      ( -> Checker.keysCount o ).should.throw()
      o = -> return 10
      ( -> Checker.keysCount o ).should.throw()
      done()

    it "object=[1,2,3]", (done) ->
      o = [1,2,3]
      Checker.keysCount(o).should.equal(3)
      done()

  describe '#checkRules', () ->
    it "REQUIRED", (done) ->
      rules = 
        'REQUIRED': true

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = ''
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = 0
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      done()

    it "LENGTH", (done) ->
      rules = 
        'LENGTH': 
          min: 1
          max: 6

      a = '123456'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = ''
      res = Checker.checkRules(a, rules)
      res.should.eql(["LENGTH:#{rules.LENGTH.min}:#{rules.LENGTH.max}"])

      a = '1234567'
      res = Checker.checkRules(a, rules)
      res.should.eql(["LENGTH:#{rules.LENGTH.min}:#{rules.LENGTH.max}"])

      a = 1
      res = Checker.checkRules(a, rules)
      res.should.eql(['STRING'])

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      done()

    it "REQUIRED, LENGTH", (done) ->
      rules = 
        'REQUIRED': true
        'LENGTH': 
          min: 1
          max: 6

      a = ''
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED', "LENGTH:#{rules.LENGTH.min}:#{rules.LENGTH.max}"])

      done()

    it "RANGE", (done) ->
      rules = 
        'RANGE': 
          min: -90
          max: 90

      a = '123456'
      res = Checker.checkRules(a, rules)
      res.should.eql(['NUMBER'])

      a = 0
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = -91
      res = Checker.checkRules(a, rules)
      res.should.eql(["RANGE:#{rules.RANGE.min}:#{rules.RANGE.max}"])

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      done()

    it "REQUIRED, RANGE", (done) ->
      rules = 
        'REQUIRED': true
        'RANGE': 
          min: -90
          max: 90

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      done()

    it "STRING", (done) ->
      rules = 
        'STRING': true 

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = true
      res = Checker.checkRules(a, rules)
      res.should.eql(['STRING'])

      a = 1234
      res = Checker.checkRules(a, rules)
      res.should.eql(['STRING'])

      done()

    it "NUMBER", (done) ->
      rules = 
        'NUMBER': true 

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = true
      res = Checker.checkRules(a, rules)
      res.should.eql(['NUMBER'])

      a = '1234'
      res = Checker.checkRules(a, rules)
      res.should.eql(['NUMBER'])

      a = 1234
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      done()

    it "INTEGER", (done) ->
      rules = 
        'INTEGER': true 

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = true
      res = Checker.checkRules(a, rules)
      res.should.eql(['INTEGER'])

      a = '1234'
      res = Checker.checkRules(a, rules)
      res.should.eql(['INTEGER'])

      a = 1234
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = -1234
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = '1234.56'
      res = Checker.checkRules(a, rules)
      res.should.eql(['INTEGER'])

      a = '-1234.56'
      res = Checker.checkRules(a, rules)
      res.should.eql(['INTEGER'])

      done()

    it "BOOLEAN", (done) ->
      rules = 
        'BOOLEAN': true 

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = true
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = false
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      done()

    it "PATTERN", (done) ->
      rules = 
        'PATTERN': /^\d+$/

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = 1234
      res = Checker.checkRules(a, rules)
      res.should.eql(['STRING'])

      a = '1234'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = '1A234'
      res = Checker.checkRules(a, rules)
      res.should.eql(['PATTERN'])

      done()

    it "STRING_INTEGER", (done) ->
      rules = 
        'STRING_INTEGER': true

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = 1234
      res = Checker.checkRules(a, rules)
      res.should.eql(['STRING'])

      a = '1234'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = '-1234'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = '1A234'
      res = Checker.checkRules(a, rules)
      res.should.eql(['STRING_INTEGER'])

      done()

    it "UNSUPPORTED", (done) ->
      rules = 
        'UNSUPPORTED': ['image/png', 'image/jpeg', 'image/gif', 'image/gif', 'audio/mpeg', 'video/h264', 'video/mp4' ]

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = '1234'
      res = Checker.checkRules(a, rules)
      res.should.eql(['UNSUPPORTED'])

      a = 'image/gif'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      done()

    it "ISODATE", (done) ->
      rules = 
        'ISODATE': true

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = '1234'
      res = Checker.checkRules(a, rules)
      res.should.eql(['ISODATE'])

      a = '19720426T12:04:20Z'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      done()

    it "NAME_INTEGER", (done) ->
      rules = 
        'NAME_INTEGER': true

      a = null
      res = Checker.checkRules(a, rules)
      res.should.eql(['REQUIRED'])

      a = '1234'
      res = Checker.checkRules(a, rules)
      res.should.eql(['NAME_INTEGER'])

      a = 'juma'
      res = Checker.checkRules(a, rules)
      res.should.eql(['NAME_INTEGER'])

      a = 'juma:1234'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      a = 'juma:-1234'
      res = Checker.checkRules(a, rules)
      res.should.eql([])

      done()
