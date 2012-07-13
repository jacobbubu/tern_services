should    = require 'should'
Tag       = require '../models/tag_mod'
Memo      = require '../models/memo_mod'
Utils     = (require 'ternlibs').utils
DeepLog   = require 'util'
DB        = require('ternlibs').database

describe 'Tag Unit Test', () ->

  userDB = DB.getDB 'UserDataDB'

  describe '#Upload Params Checking', () ->

    it "Add Params Checking", (done) ->
      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device1'
        data: [ {
          op: 1
          created_at: '20120301T12:22:78Z'
        }, {
          op: 4
        }, {

        }, {
          op: 1
          created_at: '20120301T12:22:28Z'
          tid: 'tern_test_persistent'
          key: 'xxxx'
        }
        ]

      Tag.upload request, (err, res) ->
        should.not.exist err

        #console.log DeepLog.inspect res, false, 4

        res[0].status.should.equal(-1)
        error = res[0].error
        error.created_at.should.eql(['ISODATE'])
        error.tid.should.eql(['REQUIRED'])
        error.key.should.eql(['REQUIRED'])

        res[1].status.should.equal(-1)
        error = res[1].error
        error.op.should.eql(['UNSUPPORTED'])

        res[2].status.should.equal(-1)
        error = res[2].error
        error.op.should.eql(['REQUIRED'])

        res[3].status.should.equal(-1)
        error = res[3].error
        error.tid.should.eql(['NAME_INTEGER'])
        error.key.should.eql(['TAG_KEY'])

        done()

  describe '#Upload', () ->
    tid1 = 'tern_test_persistent:' + (+new Date).toString()    
    tagKey1 = 'tern_test_persistent:Admin:' + 
              (+new Date).toString().reverse() + ':' +
              (+new Date + 1).toString().reverse() + ':' +
              (+new Date + 2).toString().reverse()

    tid2 = 'tern_test_persistent:' + (+new Date + 1).toString()
    old_ts1 = ''

    it "Add", (done) ->
      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device1'
        data: [ {
          op: 1
          tid: tid1
          created_at: '20120301T12:22:28Z'
          key: tagKey1
          value:
            ISBN: '98687788'
        }
        ]

      Tag.upload request, (err, res) ->
        should.not.exist err

        #console.log DeepLog.inspect res, false, 4

        result = res[0]
        result.status.should.equal(0)
        result.op.should.equal(1)
        result.tid.should.equal(tid1)

        result.should.have.property('ts')

        old_ts1 = result.ts

        done()

    it "Add (Same Tag Key)", (done) ->
      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device2'
        data: [ {
          op: 1
          tid: tid2
          created_at: '20120301T12:22:28Z'
          key: tagKey1
          value:
            ISBN: '98687788'
        }
        ]

      Tag.upload request, (err, res) ->
        should.not.exist err

        result = res[0]
        result.status.should.equal(-6)
        result.op.should.equal(1)
        result.tid.should.equal(tid1)

        done()

    it "Update", (done) ->

      newTagKey = 'tern_test_persistent:Admin:' +
                  (+new Date).toString().reverse() + ':' +
                  (+new Date + 1).toString().reverse()

      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device2'
        data: [ {
          op: 2
          tid: tid1
          updated_at: '20120302T00:00:00Z'
          old_ts: old_ts1
          key: newTagKey
          value: 'Nick, Hello!'
        }
        ]

      Tag.upload request, (err, res) ->
        should.not.exist err

        #console.log DeepLog.inspect res, false, 4
        
        result = res[0]
        result.status.should.equal(0)
        result.op.should.equal(2)
        result.tid.should.equal(tid1)
        old_ts1 = result.ts
        
        userDB.get 'users/tern_test_persistent/tagkey_to_tid/' + newTagKey, (err, replies) ->
          replies.should.equal(tid1)
         
          userDB.exists 'users/tern_test_persistent/tagkey_to_tid/' + tagKey1, (err, replies) ->
            replies.should.equal(0)

            tagKey1 = newTagKey
            done()

    it "Delete", (done) ->

      tagIdxs = Utils.keyToTagIdx tagKey1

      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device3'
        data: [ {
          op: 3
          tid: tid1
          deleted_at: '20120302T00:00:00Z'
          old_ts: old_ts1
        }
        ]

      Tag.upload request, (err, res) ->
        should.not.exist err
        
        userDB.exists 'users/tern_test_persistent/tagkey_to_tid/' + tagKey1, (err, replies) ->
          replies.should.equal(0, "users/tern_test_persistent/tagkey_to_tid/#{tagKey1} should not exist")

          done()

  describe '#Comprehensive (memo + tag add and delete)', () ->
    
    mid1 = 'tern_test_persistent:' + (+new Date).toString()
    old_memo_ts = ''
    tid1 = 'tern_test_persistent:' + (+new Date).toString()
    tagKey1 = 'tern_test_persistent:Book:' + (+new Date).toString().reverse()
    old_tag_ts = ''

    tid2 = 'tern_test_persistent:' + ((+new Date)+1).toString()
    tagKey2 = 'tern_test_persistent:Book:' + (+new Date+1).toString().reverse()

    tid3 = 'tern_test_persistent:' + ((+new Date)+2).toString()
    tagKey3 = 'tern_test_persistent:Book:' + (+new Date+2).toString().reverse()

    tid4 = 'tern_test_persistent:' + ((+new Date)+2).toString()
    tagKey4 = 'tern_test_persistent:Book:' + (+new Date+2).toString().reverse()

    it "Add Memo", (done) ->
      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device1'
        data: [ {
          op: 1
          created_at: '20120301T12:22:10Z'
          mid: mid1
          text: 'Comprehensive Test'
          geo:
            lat: -10
            lng: 10
          tags:
            [ { tid: tid1, c:0.8 }, { tid: tid2} ]
        } ]

      Memo.upload request, (err, res) ->
        should.not.exist err

        old_memo_ts = res[0].ts

        userDB.zrange 'users/tern_test_persistent/tid_mid/' + tid1, 0, -1, (err, replies) ->
          replies.should.include(res[0].mid)
          done()

    it "Add Tag", (done) ->
      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device1'
        data: [ {
          op: 1
          tid: tid1
          created_at: '20120301T12:22:28Z'
          key: tagKey1
          value:
            ISBN: '98687788'
        }, {
          op: 1
          tid: tid2
          created_at: '20120301T12:22:29Z'
          key: tagKey2
          value:
            ISSN: '98687781'
          parent: tid1
        }, {
          op: 1
          tid: tid3
          created_at: '20120301T12:22:29Z'
          key: tagKey3
          value:
            ISSN: '98687781'
          parent: tid2
        }, {
          op: 1
          tid: tid4
          created_at: '20120301T12:22:30Z'
          key: tagKey4
          value:
            ISSN: '98687781'
          parent: tid2
        } ]
      
      Tag.upload request, (err, res) ->
        should.not.exist err

        old_tag_ts = res[0].ts

        userDB.get 'users/tern_test_persistent/tagkey_to_tid/' + tagKey1, (err, replies) ->
          replies.should.equal(tid1)

          userDB.get 'users/tern_test_persistent/tagkey_to_tid/' + tagKey2, (err, replies) ->
            replies.should.equal(tid2)

            userDB.get 'users/tern_test_persistent/tagkey_to_tid/' + tagKey3, (err, replies) ->
              replies.should.equal(tid3)

              userDB.get 'users/tern_test_persistent/tagkey_to_tid/' + tagKey4, (err, replies) ->
                replies.should.equal(tid4)

                done()

    it "Delete Tag", (done) ->
      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device3'
        data: [ {
          op: 3
          tid: tid1
          deleted_at: '20120302T00:00:00Z'
          old_ts: old_tag_ts
        } ]

      Tag.upload request, (err, res) ->
        should.not.exist err

        userDB.exists 'users/tern_test_persistent/tagkey_to_tid/' + tagKey1, (err, replies) ->
          replies.should.equal(0)

          userDB.exists 'users/tern_test_persistent/tags/' + tid1, (err, replies) ->
            replies.should.equal(0)
          
            userDB.exists 'users/tern_test_persistent/tags/' + tid2, (err, replies) ->
              replies.should.equal(0)

              userDB.exists 'users/tern_test_persistent/tags/' + tid3, (err, replies) ->
                replies.should.equal(0)

                userDB.exists 'users/tern_test_persistent/tags/' + tid4, (err, replies) ->
                  replies.should.equal(0)

                  userDB.hget 'users/tern_test_persistent/memos/' + mid1, 'tags', (err, replies) ->
                    JSON.parse(replies).should.eql([], "tags of memo #{mid1} should be empty")
                    done()

    it "Delete Memo", (done) ->
      request =
        _tern: 
          user_id: 'tern_test_persistent'
          device_id: 'fake_device3'
        data: [ {
          op: 3
          mid: mid1
          deleted_at: '20120302T00:00:00Z'
          old_ts: old_memo_ts
        } ]

      Memo.upload request, (err, res) ->
        should.not.exist err

        userDB.exists 'users/tern_test_persistent/memos/' + mid1, (err, replies) ->
          replies.should.equal(0)
          done()
