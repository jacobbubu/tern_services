should  = require 'should'
Cache   = require '../lib/cache'

describe 'Cache Unit Test', () ->
  
  describe '#Cache Operators', () ->
    it "set/get", (done) ->
      cache = new Cache( "CacheName", {size: 100, expiry: 30000} )
      cache.set "key1", "Hello, World"
      (cache.get "key1").should.equal("Hello, World")
      done()

    it "del", (done) ->
      cache = new Cache( "CacheName", {size: 100, expiry: 30000} )
      cache.set "key1", "Hello, World"
      cache.del "key1"
      should.not.exist (cache.get "key1")
      done()

    it "expiry in 1ms", (done) ->
      cache = new Cache( "CacheName", {size: 100, expiry: 1} )
      cache.set "key1", "Hello, World"
      setTimeout ->
        should.not.exist (cache.get "key1")
        done()
      , 5
      
  describe '#Perf. Counter', () ->
    it "set/get", (done) ->
      cache = new Cache( "CacheName", {size: 100, expiry: 30000} )
      cache.set "key1", "Hello, World"
      for i in [1..1000]
        cache.get "key1"
        cache.get "key2"
      done()
