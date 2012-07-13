Log             = require('ternlibs').test_log
Path            = require 'path'
SpawnServerTest = require('ternlibs').spawn_server_test
should          = require 'should'

serverPath = Path.resolve __dirname, '../media_server.coffee'

describe 'Media Server Unit Test', () ->
    
  data = null

  describe '#Start Media Server', () ->
    it "Spawn Server Process", (done) ->
      SpawnServerTest.start serverPath, /Media Server is listening on/i, () ->
        done()

  describe '#Stop Media Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()