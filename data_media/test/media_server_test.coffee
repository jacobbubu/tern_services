SpawnServerTest = require('ternlibs').spawn_server_test
DefaultPorts    = require('ternlibs').default_ports
Log             = require('ternlibs').test_log
Path            = require 'path'
should          = require 'should'
Request         = require('request')
TestData        = require './test_data'
FS              = require 'fs'


serverPath = Path.resolve __dirname, '../media_server.coffee'
memoMediaUri = [DefaultPorts.MediaWeb.uri, '1/memos'].join '/'
commentMediaUri = [DefaultPorts.MediaWeb.uri, '1/comments'].join '/'
media_id = 'tern_test_persistent:001'
nonexistent_media_id = 'tern_test_persistent:9999999999999999'
uploadFile = './test/TEST.JPG'
uploadFileLength = FS.statSync(uploadFile).size

shouldHaveErrorStatus = (body, status) ->
  errObj = JSON.parse body
  errObj.should.have.property('status')
  errObj.status.should.equal status


describe 'Media Server Unit Test', () ->
    
  describe '#Start Media Server', () ->
    it "Spawn Server Process", (done) ->
      SpawnServerTest.start serverPath, /Media Server is listening on/i, () ->
        done()

  describe '#Access Token Verify', () ->
    it "No authorization header", (done) ->
      Request.get { uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err        
        res.should.have.status(401)

        errObj = JSON.parse body
        errObj.should.have.property('status')
        errObj.should.have.property('message')
        done()

    it "Bad authorization method", (done) ->
      headers =
        authorization : "badMethod " + TestData.access_token

      Request.get { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err
        res.should.have.status(401)
        errObj = JSON.parse body
        errObj.should.have.property('status')
        errObj.should.have.property('message')        
        done()

    it "Invalid access_token", (done) ->
      headers =
        authorization : "Bearer " + "BAD_TOKEN"

      Request.get { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err
        res.should.have.status(401)
        errObj = JSON.parse body
        errObj.should.have.property('status')
        errObj.should.have.property('message')        
        done()

    it "Unmatched media_id and user_id", (done) ->
      headers =
        authorization : "Bearer " + TestData.access_token

      Request.get { headers: headers, uri: memoMediaUri + '/' + 'juma:001' }, (err, res, body) ->
        should.not.exist err
        res.should.have.status(403)
        errObj = JSON.parse body
        errObj.should.have.property('status')
        errObj.should.have.property('message')        
        done()

    it "Success", (done) ->
      headers =
        authorization : "Bearer " + TestData.access_token

      Request.get { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err
        res.should.have.status(200)
        errObj = JSON.parse body
        errObj.should.not.have.property('status')
        errObj.should.not.have.property('message')
        done()

  describe '#Upload headers check', () ->

    it "Content-Range required", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : 0
        'content-type'    : "video/x-m4v"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(400)
        shouldHaveErrorStatus body, -2011
        done()

    it "Invalid unit in Content-Range", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : 0
        'content-range'   : "INVALID_UNIT */100"        
        'content-type'    : "video/x-m4v"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(400)
        shouldHaveErrorStatus body, -2012
        done()

    it "Invalid instance length in Content-Range", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : 0
        'content-range'   : "bytes *"        
        'content-type'    : "video/x-m4v"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(400)
        shouldHaveErrorStatus body, -2013
        done()

    it "Instance length in Content-Range is out of range", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : 0
        'content-range'   : "bytes */2000000000"
        'content-type'    : "video/x-m4v"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(400)
        shouldHaveErrorStatus body, -2014
        done()

    it "Content-Type required", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : 0
        'content-range'   : "bytes */100"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(400)
        shouldHaveErrorStatus body, -2021
        done()

    it "Unsupported Content-Type", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : 0
        'content-range'   : "bytes */100"
        'content-type'    : "image/x-icon"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(415)
        shouldHaveErrorStatus body, -2022
        done()

    it "Content-Length is out of range", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-range'   : "bytes */100"
        'content-type'    : "video/x-m4v"

      body = new Buffer(4 * 1024 * 1024 +1)
      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id, body }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(413)
        shouldHaveErrorStatus body, -2002
        done()

    it "Success with status 308 and empty body", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-range'   : "bytes */100"
        'content-type'    : "video/x-m4v"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err
        should.not.exist body
        res.headers.should.have.property('range')
        Log.clientLog 'range: ' + res.headers.range
        res.should.have.status(308)
        done()

  describe '#Media upload', () ->
    it "File upload (#{uploadFileLength})", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : uploadFileLength
        'content-range'   : "bytes 0-#{uploadFileLength-1}/#{uploadFileLength}"
        'content-type'    : "image/jpeg"

      FS.createReadStream(uploadFile).pipe(Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(200)
        done()
      )

    it "Same file, 200 Expected", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : uploadFileLength
        'content-range'   : "bytes 0-#{uploadFileLength-1}/#{uploadFileLength}"
        'content-type'    : "image/jpeg"

      FS.createReadStream(uploadFile).pipe(Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(200)
        done()
      )

    it "Delete this file", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token

      Request.del { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(200)
        done()
  
  describe '#Media upload-resumable', () ->

    partLength = (uploadFileLength / 3).toFixed(0)
    fileContent = FS.readFileSync(uploadFile)
    part1 = fileContent.slice(0, partLength)
    part2 = fileContent.slice(partLength, 2 * partLength)
    part3 = fileContent.slice(2 * partLength, uploadFileLength)

    it "Part1 (#{part1.length})", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : part1.length
        'content-range'   : "bytes 0-#{part1.length-1}/#{uploadFileLength}"
        'content-type'    : "image/jpeg"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id, body: part1 }, (err, res, body) ->
        should.not.exist err
        [start, end] = res.headers['range'].split '-'
        (new Number(end) + 1).should.equal(part1.length)
        res.should.have.status(308)        
        done()

    it "Part2 (#{part2.length})", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : part2.length
        'content-range'   : "bytes #{part1.length}-#{part1.length + part2.length - 1}/#{uploadFileLength}"
        'content-type'    : "image/jpeg"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id, body: part2 }, (err, res, body) ->
        should.not.exist err
        [start, end] = res.headers['range'].split '-'
        (new Number(end) + 1).should.equal(part1.length + part2.length)
        res.should.have.status(308)        
        done()

    it "Part3 (#{part3.length})", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'content-length'  : part3.length
        'content-range'   : "bytes #{part1.length + part2.length}-#{part1.length + part2.length + part3.length - 1}/#{uploadFileLength}"
        'content-type'    : "image/jpeg"

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id, body: part3 }, (err, res, body) ->
        should.not.exist err
        should.not.exist body        
        res.should.have.status(200)        
        done()

    it "Delete this file", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token

      Request.del { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(200)
        done()      
     
  describe '#Delete media file', () ->
    it "Delete a nonexistent file", (done) ->
      headers =
        'authorization'   : "Bearer " + TestData.access_token

      Request.del { headers: headers, uri: memoMediaUri + '/' + nonexistent_media_id }, (err, res, body) ->
        should.not.exist err

        res.should.have.status(200)
        done()

  describe '#Stop Server', () ->
    it "SIGINT", (done) ->
      SpawnServerTest.stop () ->
        done()