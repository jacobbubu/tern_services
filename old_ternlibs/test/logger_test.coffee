should  = require 'should'
Log     = require '../lib/logger'

describe 'Logger Unit Test', () ->

    describe '#initialize', () ->
      it 'You should see "Hello, Logger!"', (done) ->
        Log.info "LogTest: Hello, Logger!"
        Log.alert "LogTest: Hello, Logger!"
        done()
