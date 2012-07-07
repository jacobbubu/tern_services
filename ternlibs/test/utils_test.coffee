should  = require 'should'
Utils   = require '../lib/utils'
Async   = require "async"
Lzf     = require '../lib/lzf'

key_iv =
  key: "8eb5575e940893ebd78c8df499e6541f"
  iv:  "1f07c9e9866d53cf5f1005464fc8f474"

#key = "8eb5575e940893eb"
#Cipher = Crypto.createCipher("rc4-40", new Buffer(key, "hex").toString("binary"))
#Decipher = Crypto.createDecipher("rc4-40", new Buffer(key, "hex").toString("binary"))

describe 'Utils Unit Test', () ->

  describe '#Password Hash', () ->
    it 'Generate password hash', (done) ->
      hashedPassword = Utils.passwordHash("MyPassword1234")
      console.log hashedPassword
      Utils.verifyPassword("MyPassword1234", "sha1$pzlzHKmd$1$0f3180b6035ac423f2ed032876c62735ed5650d5").should.be.true
      done()

    it 'Verify password hash', (done) ->
      hashedPassword = Utils.passwordHash("MyPassword1234")
      Utils.verifyPassword("MyPassword1234", "sha1$pzlzHKmd$1$0f3180b6035ac423f2ed032876c62735ed5650d5").should.be.true
      Utils.verifyPassword("MyPassword1234", "sha1$GD425zsr$1$d91cfa625158198fc192f5363ba8efc1131c7776").should.be.true
      Utils.verifyPassword("MyPassword1234", "sha1$O6b3T5nu$1$53777f122d3c7a806e77e61ed38068893882def7").should.be.true
      Utils.verifyPassword("MyPassword1234", "sha1$URlGZErx$1$80cd7fd44ccbb608c7d77328addc7bfcf2b8b49a").should.be.true
      Utils.verifyPassword("MyPassword1234", "xxxxxxxxxxxx").should.be.false
      done()

  describe '#Date', () ->
    it 'UTCString Now', (done) -> 
      res = Utils.UTCString()
      arr = res.split 'T'
      arr.length.should.equal(2)
      arr[0].length.should.equal(8)
      arr[1].length.should.equal(7)
      done()

    it 'UTCString 1-1-1 0:0:0', (done) -> 
      date = new Date
      date.setUTCFullYear 1
      date.setUTCMonth 0
      date.setUTCDate 1
      date.setUTCHours 0
      date.setUTCMinutes 0
      date.setUTCSeconds 0
      Utils.UTCString(date).should.equal("00010101T000000Z")
      done()

  describe '#compressAndEncrypt', () ->
    it 'Success', (done) -> 
      message = '{"req_ts":631370001,"body":"2"}'

      Utils.compressAndEncrypt message, key_iv, (err, buffer) ->
        should.not.exist err
        Buffer.isBuffer(buffer).should.be.true

        Utils.decryptAndUncompress buffer, key_iv, (err, res) ->
          should.not.exist err

          res.should.equal(message)
          done()

    it "Performance: 1,000 times ecrypt/decrypt with compress", (done) ->

      i = 0
      message = "Juma is a little girl, her age is #{i}"

      Async.whilst(
          -> i < 1000
        , (next) ->
          i++
          Utils.compressAndEncrypt message, key_iv, (err, buffer) ->
            should.not.exist err
            Buffer.isBuffer(buffer).should.be.true

            Utils.decryptAndUncompress buffer, key_iv, (err, res) ->
              should.not.exist err

              res.should.equal(message)
          next()
        , (err) ->
          should.not.exist err
          done()
      )

  describe '#Encrypt/Decrypt', () ->
    it 'Success', (done) -> 
      message = '{"req_ts":631370001,"body":"2"}'

      encryptedBuffer = Utils.encrypt message, key_iv
      decryptedMessage = Utils.decrypt encryptedBuffer, key_iv

      decryptedMessage.should.equal(message)
      done()

    it "Performance: 1,000 times ecrypt/decrypt without compress", (done) ->

      message = "Juma is a little girl, her age is #{i}"

      for i in [1..1000]
        encryptedBuffer = Utils.encrypt message, key_iv
        decryptedMessage = Utils.decrypt encryptedBuffer, key_iv
        decryptedMessage.should.equal(message)
      done()

  describe '#lzfAndEncrypt', () ->
    it 'Success', (done) -> 
      message = """ {"req_ts":21940000,"response":{"method":"ping","status":0}} """
      #encryptedBuffer = Lzf.compress message
      #decryptedMessage = Lzf.decompress encryptedBuffer
      encryptedBuffer = Utils.lzfAndEncrypt message, key_iv
      decryptedMessage = Utils.decryptAndUnlzf encryptedBuffer, key_iv
      decryptedMessage.should.equal(message)
      done()

  describe '#getTimestamp', () ->
    it 'getTimestamp', (done) ->
      result = []
      for i in [1..20]
        result.push Utils.getTimestamp()

      result.length.should.equal(result.unique().length)
      done()