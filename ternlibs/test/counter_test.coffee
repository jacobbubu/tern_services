should  = require 'should'
Counter = require '../lib/counter'

describe 'Counter Unit Test', () ->
  
  describe '#Counter Operators', () ->
    it "next", (done) ->
      c = new Counter()
      v = c.next()
      v.length.should.equal(19)
      pid = + v.slice(-8, -3)
      pid.should.equal(process.pid)
      done()

    it "Counter.counterToDate", (done) ->
      d = Counter.counterToDate('1262501842955884000')
      (+d).should.equal(1338001018429)
      done()
