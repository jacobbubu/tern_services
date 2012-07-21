SpawnServerTest = require('ternlibs').spawn_server_test
DefaultPorts    = require('ternlibs').default_ports
Log             = require('ternlibs').test_log
Utils           = require('ternlibs').utils
Path            = require 'path'
should          = require 'should'
Request         = require('request')
TestData        = require './test_data'
FS              = require 'fs'
MediaFileTest   = require './media_file_test'
Crypto          = require 'crypto'
MediaFile       = require '../models/media_file_mod'

serverPath = Path.resolve __dirname, '../media_server.coffee'
memoMediaUri = [DefaultPorts.MediaWeb.uri, '1/memos'].join '/'
commentMediaUri = [DefaultPorts.MediaWeb.uri, '1/comments'].join '/'
media_id = 'tern_test_persistent:001'
nonexistent_media_id = 'tern_test_persistent:9999999999999999'
uploadFile = './test/TEST.JPG'
tempFile = './test/TEMP.JPG'
uploadFileMD5 = Utils.hexToBase64 'ca629506e59c54cdf262bed0b60efccc'
uploadFileLength = FS.statSync(uploadFile).size

shouldHaveErrorStatus = (body, status) ->
  errObj = JSON.parse body
  errObj.should.have.property('status')
  errObj.status.should.equal status

uploadMediaFile = (title, next) ->

  title = title ? "Media upload (#{uploadFileLength})"
  it title, (done) ->
    headers =
      'authorization'   : "Bearer " + TestData.access_token
      'content-length'  : uploadFileLength
      'content-range'   : "bytes 0-#{uploadFileLength-1}/#{uploadFileLength}"
      'content-type'    : "image/jpeg"
      'x-instance-md5'  : uploadFileMD5

    FS.createReadStream(uploadFile).pipe(Request.put { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
      should.not.exist err

      res.should.have.status(200)
      if next?
        next err, res, body, done
      else
        done()
    )

deleteMediaFile = (media_id) ->
  it "Delete media '#{media_id}'", (done) ->
    headers =
      'authorization'   : "Bearer " + TestData.access_token

    Request.del { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
      should.not.exist err

      res.should.have.status(200)
      done()

fileCompare = (file1, file2) ->
  file1Buf = FS.readFileSync(file1)
  file2Buf = FS.readFileSync(file2)
  return file1Buf.toString('binary') is file2Buf.toString('binary')

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

    it "Success with 404", (done) ->
      headers =
        authorization : "Bearer " + TestData.access_token

      Request.get { headers: headers, uri: memoMediaUri + '/' + media_id }, (err, res, body) ->
        should.not.exist err
        res.should.have.status(404)
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
    uploadMediaFile "Upload then ranged get"

    it "Read back to compare", (done) ->
      MediaFileTest.readFile media_id, (err, fileData) ->
        fileData.toString('binary').should.equal(FS.readFileSync(uploadFile).toString('binary'))
        done()

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

    deleteMediaFile media_id
  
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
        'x-instance-md5'  : uploadFileMD5

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
        'x-instance-md5'  : uploadFileMD5

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
        'x-instance-md5'  : uploadFileMD5

      Request.put { headers: headers, uri: memoMediaUri + '/' + media_id, body: part3 }, (err, res, body) ->
        should.not.exist err
        should.not.exist body
        res.should.have.status(200)        
        done()

    it "Read back to compare", (done) ->
      MediaFileTest.readFile media_id, (err, fileData) ->
        fileData.toString('binary').should.equal(fileContent.toString('binary'))
        done()

    deleteMediaFile media_id      
     
  describe '#Media Stream-Ranged Get', () ->
    uploadMediaFile "Upload then ranged get", (err, res, body, done) ->

      partLength = (uploadFileLength / 3).toFixed(0)

      MediaFile.createReadStream media_id, {start: 0, end: partLength - 1}, (err, stream) ->
        should.not.exist err
        should.exist stream

        fsStream = FS.createWriteStream(tempFile)

        fsStream.on 'close', ->
          MediaFile.createReadStream media_id, {start: partLength, end: partLength * 2 - 1}, (err, stream) ->
            should.not.exist err
            should.exist stream

            fsStream = FS.createWriteStream(tempFile, {flags: 'a'})

            fsStream.on 'close', ->
              MediaFile.createReadStream media_id, {start: partLength * 2, end: uploadFileLength - 1}, (err, stream) ->
                should.not.exist err
                should.exist stream

                fsStream = FS.createWriteStream(tempFile, {flags: 'a'})

                fsStream.on 'close', ->
                  (fileCompare uploadFile, tempFile).should.be.true
                  FS.unlinkSync tempFile
                  done()

                stream.pipe fsStream

            stream.pipe fsStream

        stream.pipe fsStream

    deleteMediaFile media_id

  describe '#HTTP get media file', () ->
    
    uploadMediaFile "Upload then ranged get", (err, res, body, done) ->

      partLength = (uploadFileLength / 3).toFixed(0)

      headers =
        'authorization'   : "Bearer " + TestData.access_token
        'range'           : "bytes=" + "0-#{partLength - 1}"

      fsStream = FS.createWriteStream(tempFile)
      (Request.get { headers: headers, uri: memoMediaUri + '/' + media_id }).pipe(fsStream)

      fsStream.on 'close', ->
        headers =
          'authorization'   : "Bearer " + TestData.access_token
          'range'           : "bytes=" + "#{partLength}-#{partLength * 2 - 1}"

        fsStream = FS.createWriteStream(tempFile, {flags: 'a'})
        (Request.get { headers: headers, uri: memoMediaUri + '/' + media_id }).pipe(fsStream)

        fsStream.on 'close', ->
          headers =
            'authorization'   : "Bearer " + TestData.access_token
            'range'           : "bytes=" + "#{partLength * 2}-}"

          fsStream = FS.createWriteStream(tempFile, {flags: 'a'})
          (Request.get { headers: headers, uri: memoMediaUri + '/' + media_id }).pipe(fsStream)

          fsStream.on 'close', ->
            (fileCompare uploadFile, tempFile).should.be.true
            FS.unlinkSync tempFile
            done()

    deleteMediaFile media_id

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