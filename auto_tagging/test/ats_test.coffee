should        = require 'should'
DeepLog       = require 'util'
Utils         = require 'tern.utils'
DB            = require 'tern.database'
BrokersHelper = require('tern.central_config').BrokersHelper

TestData      = require '../../data_media/test/test_data'
Memo          = null
userDB        = null

createMemo = () ->

  it "Create Memo: #{mid}", (done) ->
    request =
      _tern: 
        user_id: TestData.user_id
        device_id: 'fake_device1'
      data: [ {
        op: 1
        created_at: Utils.UTCString()
        mid: mid
        media_meta:
          content_type: 'image/jpeg'
          content_length: 256000
          md5: hexMD5
        geo:
          lat: 39.915833
          lng: 116.390556
        tags: [ 
            { tid: "#{TestData.user_id}:001", c:0.8 }
          , { tid: "#{TestData.user_id}:002"}
          , { tid: "#{TestData.user_id}:003"}
        ]
      }
      ]

    userDB = DB.getDB 'userDBShards', TestData.user_id unless userDB?

    Memo.upload request, (err, res) ->
      should.not.exist err

      first_result = res[0]
      first_result.op.should.equal(1)
      first_result.status.should.equal(0)
      first_result.should.have.property('ts')
      first_result.mid.should.equal(mid)
      old_ts = first_result.ts

      userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:001", 0, -1, (err, replies) ->
        replies.should.include(first_result.mid)

        userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:002", 0, -1, (err, replies) ->
          replies.should.include(first_result.mid)

          userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:003", 0, -1, (err, replies) ->
            replies.should.include(first_result.mid)

            done()

deleteMemo = () -> 
  it "Delete Memo: #{mid}", (done) ->
    request =
      _tern: 
        user_id: TestData.user_id
        device_id: 'fake_device1'
      data: [ {
        op: 3
        mid: mid
        old_ts: old_ts
        deleted_at: Utils.UTCString()
      }
      ]

    userDB = DB.getDB 'userDBShards', TestData.user_id unless userDB?

    Memo.upload request, (err, res) ->
      should.not.exist err

      result = res[0]    
      result.op.should.equal(3)
      result.status.should.equal(1)
      result.should.have.property('ts')
      result.mid.should.equal(mid)

      # Fill in new ts
      request.data[0].old_ts = result.ts

      Memo.upload request, (err, res) ->

        result = res[0]      
        result.op.should.equal(3)
        result.status.should.equal(0)
        result.should.have.property('ts')
        result.mid.should.equal(mid)

        userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:001", 0, -1, (err, replies) ->
          replies.should.not.include(result.mid)

          userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:002", 0, -1, (err, replies) ->
            replies.should.not.include(result.mid)

            userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:003", 0, -1, (err, replies) ->
              replies.should.not.include(result.mid)
              
              userDB.zrange "users/#{TestData.user_id}/tid_mid/#{TestData.user_id}:004", 0, -1, (err, replies) ->                
                replies.should.not.include(result.mid)
                done()
                
describe 'ATS Unit Test', () ->

  describe '#Init config brokers', () ->
    it "Init", (done) ->
      BrokersHelper.init ->
        userDB = DB.getDB 'userDBShards', TestData.user_id unless userDB?
        done()
