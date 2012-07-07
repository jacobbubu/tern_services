should  = require 'should'
Log     = require '../lib/logger'
Perf    = require '../lib/perf_counter'

describe 'Perf. Counter Unit Test', () ->

    describe "#Perf.increment", () ->

      it "'perf.unittest.counter' without sample", (done) ->
        Perf.increment 'perf.unittest.counter'
        done()

      it "'perf.unittest.counter' with sample 0.1", (done) ->
        Perf.increment 'perf.unittest.counter', 0.1
        done()

    describe "#Perf.decrement", () ->

      it "'perf.unittest.counter' without sample", (done) ->
        Perf.decrement 'perf.unittest.counter'
        done()

      it "'perf.unittest.counter' with sample 0.1", (done) ->
        Perf.decrement 'perf.unittest.counter', 0.1
        done()

    describe "#Perf.timing", () ->

      it "'perf.unittest.timing, 3288' without sample", (done) ->
        Perf.timing 'perf.unittest.timing', 3288
        done()

      it "'perf.unittest.timing, 3288, 0.1' with sample 0.1", (done) ->
        Perf.timing 'perf.unittest.timing', 3288, 0.1
        done()
    ###
    describe "#Batch call", () ->

      times = 10000
      
      it "#{times} times", (done) ->
        start = (new Date).getTime()
        for i in [1..times]
          Perf.increment 'perf.unittest.counter'

        end = (new Date).getTime()
        Perf.timing 'perf.unittest.timing', start - end
        done()

    ###