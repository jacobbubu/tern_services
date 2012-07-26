should    = require 'should'
Memo      = require '../models/memo_mod'
Utils     = (require 'ternlibs').utils
DB        = require('ternlibs').database
DeepLog   = require 'util'
TestData  = require './test_data'

describe 'Memo Unit Test', () ->

  userDB = DB.getDB 'UserDataDB'

  describe '#Upload Params Checking', () ->
    it "Add Params Checking", (done) ->
      request =
        _tern: 
          user_id: TestData.user_id
          device_id: 'fake_device1'
        data: [ {
          op: 1
          created_at: '20120301T12:22:78Z'
          media_meta:
            content_type: 'oddtype'
            content_length: 'not integer'
            md5: ''
          geo:
            lat: -190
          tags: {
            'xxx': { key: TestData.user_id}
          }
        }, {
          op: 4
        }, {

        }, {
          op: 1
          created_at: '20120301T12:22:02Z'
          tags: [ {xxx: ''} ]
        }, {
          op: 1
          created_at: '20120301T12:22:02Z'
          text: Utils.createString('*', 2049)
          tags: [
              { 'tid': "#{TestData.user_id}:001" }
            , { 'tid': 'hi, bad' }
          ]
        } 

        ]

      Memo.upload request, (err, res) ->
        should.not.exist err

        #console.log DeepLog.inspect res, false, 3

        res[0].status.should.equal(-1)
        error = res[0].error
        error.mid.should.eql(['REQUIRED'])
        error.created_at.should.eql(['ISODATE'])
        error['media_meta.content_type'].should.eql(['UNSUPPORTED'])
        error['media_meta.content_length'].should.eql(['INTEGER'])
        #error['media_meta.md5'].should.eql(['LENGTH:32:32'])
        error['geo.lat'].should.eql([ 'RANGE:-90:90' ])
        error['geo.lng'].should.eql(['REQUIRED'])
        #error['tags'].should.eql(['ARRAY'])

        res[1].status.should.equal(-1)
        error = res[1].error
        error.op.should.eql(['UNSUPPORTED'])

        res[2].status.should.equal(-1)
        error = res[2].error
        error.op.should.eql(['REQUIRED'])

        res[3].status.should.equal(-1)
        error = res[3].error
        error.mid.should.eql(['REQUIRED'])
        error.media_meta.should.eql(['REQUIRED_EITHER:media_meta:text'])
        error['tags[0].tid'].should.eql(['REQUIRED'])

        res[4].status.should.equal(-1)
        error = res[4].error
        error.mid.should.eql(['REQUIRED'])
        error.text.should.eql(['LENGTH:0:2048'])
        error['tags[1].tid'].should.eql(['NAME_INTEGER'])

        done()

    it "Update Params Checking", (done) ->
      request =
        _tern: 
          user_id: TestData.user_id
          device_id: 'fake_device1'      
        data: [ {
          op: 2
          mid: 'bb'
          updated_at: '20120301T12:22:78Z'
          old_ts: 'AAAA'
          media_meta:
            content_type: 'oddtype'
            content_length: 'not integer'
            md5: ''
          geo:
            lat: -190
        } ]

      Memo.upload request, (err, res) ->
        should.not.exist err
        res[0].status.should.equal(-1)
        error = res[0].error
        error.mid.should.eql(['NAME_INTEGER'])
        error.updated_at.should.eql(['ISODATE'])
        error.old_ts.should.eql(['STRING_INTEGER'])
        error['media_meta.content_type'].should.eql(['UNSUPPORTED'])
        error['media_meta.content_length'].should.eql(['INTEGER'])
        error['media_meta.md5'].should.eql(['LENGTH:32:32'])
        error['geo.lat'].should.eql([ 'RANGE:-90:90' ])
        error['geo.lng'].should.eql(['REQUIRED'])

        done()

    it "Delete Params Checking", (done) ->
      request =
        _tern: 
          user_id: TestData.user_id
          device_id: 'fake_device1'      
        data: [ {
          op: 3
          mid: 'bb'
          old_ts: 'AAAA'
          deleted_at: '20120301T12:22:78Z'
        } ]

      Memo.upload request, (err, res) ->
        should.not.exist err

        #console.log DeepLog.inspect res, false, 3

        res[0].status.should.equal(-1)
        error = res[0].error
        error.mid.should.eql(['NAME_INTEGER'])
        error.old_ts.should.eql(['STRING_INTEGER'])
        error.deleted_at.should.eql(['ISODATE'])

        done()

  describe '#Upload Success', () ->

    mid1 = "#{TestData.user_id}:" + (+new Date).toString()
    old_ts1 = ''
    mid2 = "#{TestData.user_id}:" + (+new Date + 1).toString()
    old_ts2 = ''

    updated_ts = ''

    it "Add", (done) ->
      request =
        _tern: 
          user_id: TestData.user_id
          device_id: 'fake_device1'
        data: [ {
          op: 1
          created_at: '20120301T12:22:10Z'
          mid: mid1
          media_meta:
            content_type: 'image/jpeg'
            content_length: 256000
            md5: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
          geo:
            lat: -10
            lng: 10
          tags: [ 
              { tid: "#{TestData.user_id}:001", c:0.8 }
            , { tid: "#{TestData.user_id}:002"}
            , { tid: "#{TestData.user_id}:003"}
          ]
        }, {
          op: 1
          created_at: '20120301T12:22:10Z'
          mid: mid2
          media_meta:
            content_type: 'image/jpeg'
            content_length: 256000
            md5: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
          geo:
            lat: -10
            lng: 10
        }
        ]

      Memo.upload request, (err, res) ->
        should.not.exist err

        #console.log DeepLog.inspect res, false, 3

        first_result = res[0]
        first_result.op.should.equal(1)
        first_result.status.should.equal(0)
        first_result.should.have.property('ts')
        old_ts1 = first_result.ts
        first_result.mid.should.equal(mid1)

        result = res[1]
        result.op.should.equal(1)
        result.status.should.equal(0)
        result.should.have.property('ts')
        old_ts2 = result.ts
        result.mid.should.equal(mid2)

        userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:001", 0, -1, (err, replies) ->
          replies.should.include(first_result.mid)

          userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:002", 0, -1, (err, replies) ->
            replies.should.include(first_result.mid)

            userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:003", 0, -1, (err, replies) ->
              replies.should.include(first_result.mid)

              done()

    it "Update", (done) ->
      request =
        _tern: 
          user_id: TestData.user_id
          device_id: 'fake_device2'
        data: [ {
          op: 2
          mid: mid1
          old_ts: old_ts1
          updated_at: '20120302T12:22:10Z'
          media_meta:
            content_type: 'image/png'
            content_length: 512000
            md5: 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'
          geo:
            lat: -1
            lng: 1
          tags: [ 
              { tid: "#{TestData.user_id}:003"}
            , { tid: "#{TestData.user_id}:004"}
          ]
        }
        ]

      Memo.upload request, (err, res) ->
        should.not.exist err

        result = res[0]
        result.op.should.equal(2)
        result.status.should.equal(0)
        result.should.have.property('ts')
        old_ts1 = result.ts
        result.mid.should.equal(mid1)

        userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:001", 0, -1, (err, replies) ->
          replies.should.not.include(result.mid)

          userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:002", 0, -1, (err, replies) ->
            replies.should.not.include(result.mid)

            userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:003", 0, -1, (err, replies) ->
              replies.should.include(result.mid)

              userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:004", 0, -1, (err, replies) ->                
                replies.should.include(result.mid)
                done()

    it "Delete", (done) ->
      request =
        _tern: 
          user_id: TestData.user_id
          device_id: 'fake_device3'
        data: [ {
          op: 3
          mid: mid1
          old_ts: old_ts1
          deleted_at: '20120302T13:23:10Z'
        }, {
          op: 3
          mid: mid2
          old_ts: old_ts1
          deleted_at: '20120302T13:23:10Z'
        }
        ]

      Memo.upload request, (err, res) ->
        should.not.exist err

        result = res[0]
        result.op.should.equal(3)
        result.status.should.equal(0)
        result.should.have.property('ts')
        result.mid.should.equal(mid1)

        result = res[1]
        result.op.should.equal(3)
        result.status.should.equal(0)
        result.should.have.property('ts')
        result.mid.should.equal(mid2)

        userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:001", 0, -1, (err, replies) ->
          replies.should.not.include(result.mid)

          userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:002", 0, -1, (err, replies) ->
            replies.should.not.include(result.mid)

            userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:003", 0, -1, (err, replies) ->
              replies.should.not.include(result.mid)
              
              userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:004", 0, -1, (err, replies) ->                
                replies.should.not.include(result.mid)
                done()
###