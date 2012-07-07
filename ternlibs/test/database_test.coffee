should  = require 'should'
DB      = require '../lib/database'

describe 'Database Unit Test', () ->
  
  describe '#getDB', () ->
    it "TestDB", (done) ->
      db = DB.getDB("TestDB")
      db._name.should.equal("TestDB")

      db.info (err, res) ->
        should.not.exist err
        (/redis_version/.test res).should.be.true
        done()

  describe '#run_script', () ->
    it 'eval "return 10"', (done) ->
      db = DB.getDB("TestDB")
      script = 'return 10'
      sha1 = "080c414e64bca1184bc4f6220a19c4d495ac896d"

      db.run_script script, 0, (err, res) ->
        should.not.exist err
        res.should.equal(10)
        db._scripts[script].should.equal(sha1)
        done()

    it 'eval "return 10"-params using array', (done) ->
      db = DB.getDB("TestDB")
      script = 'return 10'
      sha1 = "080c414e64bca1184bc4f6220a19c4d495ac896d"

      db.run_script script, [0], (err, res) ->
        should.not.exist err
        res.should.equal(10)
        db._scripts[script].should.equal(sha1)
        done()

    it 'eval "return {KEYS[1], ARGV[1], ARGV[2]}" 1 key1 first second', (done) ->
      db = DB.getDB("TestDB")
      script = 'return {KEYS[1], ARGV[1], ARGV[2]}'
      sha1 = "4cfb4166ae4c0001fb4259c299bc0d8595c56cc2"

      db.run_script script, 1, "key1", "first", "second", (err, res) ->
        should.not.exist err
        db._scripts[script].should.equal(sha1)
        res.should.have.length(3)
        res.should.eql(["key1", "first", "second"])
        done()

    it 'eval "return {KEYS[1], ARGV[1], ARGV[2]}" 1 key1 first second-params using array', (done) ->
      db = DB.getDB("TestDB")
      script = 'return {KEYS[1], ARGV[1], ARGV[2]}'
      sha1 = "4cfb4166ae4c0001fb4259c299bc0d8595c56cc2"

      db.run_script script, [1, "key1", "first", "second"], (err, res) ->
        should.not.exist err
        db._scripts[script].should.equal(sha1)
        res.should.have.length(3)
        res.should.eql(["key1", "first", "second"])
        done()

  describe '#del_keys', () ->
    it "del_keys 'foo'", (done) ->
      db = DB.getDB("TestDB")
      db.set "foo", "bar", (err, res) ->
        db.del_keys "foo", (err, res) ->
          res.should.equal(1)
          done()

    it "del_keys 'foo?'", (done) ->
      db = DB.getDB("TestDB")
      db.mset "foo1", "bar1", "foo2", "bar2", (err, res) ->
        db.del_keys "foo?", (err, res) ->
          res.should.equal(2)
          done()


