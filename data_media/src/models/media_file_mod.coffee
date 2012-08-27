Mongodb   = require('mongodb').Db
Server    = require('mongodb').Server
GridStore = require('mongodb').GridStore
Chunk     = require('mongodb').Chunk
Client    = require("redis").createClient()
Assert    = require('assert')

BrokersHelper = require('tern.central_config').BrokersHelper

Log           = require('tern.logger')
RedisClient   = require('tern.database')

GStream       = require('./gridstore_stream')

Config = BrokersHelper.getConfig('databases/mediaMongo').value

deleteChunks = (self, callback) ->
  if(self.fileId != null) 
    self.chunkCollection (err, collection) ->
      return callback(err, false) if err?

      collection.remove {'files_id': self.fileId}, {safe:true}, (err, result) ->
        return callback(err, false) if err?

        callback(null, true)
  else
    callback(null, true)


GridStore.unlinkReturnCount = (db, name, options, callback) ->
  self = this
  args = Array.prototype.slice.call(arguments, 2)
  callback = args.pop()
  options = if args.length > 0 then args.shift() else null

  gStore = new GridStore(db, name, "w", options)

  gStore.open (err, gridStore) ->
    return callback(err) if err?

    deleteChunks gridStore, (err, result) ->
      return callback(err) if err?

      gridStore.collection (err, collection) ->
        return callback(err) if err?

        collection.remove {'_id': gridStore.fileId}, {safe:true}, (err, numberOfRemovedMedia) ->
          callback(err, numberOfRemovedMedia)

#mediaFileInfo:
# chunkSize
# media_id

# 
# atime, mtime, ctime
# currentLength
# md5
# contentType
# instanceLength

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _MediaFile

class _MediaFile
  constructor: () ->
    @db = new Mongodb( 'TernMedia', new Server(Config.host, Config.port) )
    @redisLock = RedisClient.getDB 'RedisLockDB'
    @lock = require('redis-lock')(@redisLock)

  stat: (media_id, next) =>
    @lock media_id, (lockDone) =>
      GridStore.exist @db, media_id, (err, existence) =>
        (lockDone -> return next err) if err?

        unless existence
          lockDone ->
            stats = 
              currentLength   : 0
              contentType     : 'unknown'
              chunkSize       : NaN
              ctime           : 0
              atime           : 0
              mtime           : 0
              instanceLength  : NaN
              instanceMD5     : ''

            next null, stats
        else
          mediaFile = new GridStore(@db, media_id, 'r')
          mediaFile.open (err, mediaFile) =>
            lockDone ->
              return next err if err?

              stats = 
                currentLength   : mediaFile.length
                contentType     : mediaFile.contentType
                chunkSize       : mediaFile.chunkSize
                ctime           : mediaFile.metadata.createDate
                atime           : mediaFile.metadata.accessDate
                mtime           : mediaFile.metadata.modifyDate
                instanceLength  : mediaFile.metadata.instanceLength
                instanceMD5     : mediaFile.metadata.instanceMD5
              next null, stats

  unlink: (media_id, next) =>
    @lock media_id, (lockDone) =>
      GridStore.unlinkReturnCount @db, media_id, (err, numberOfRemovedDocs) -> 
        lockDone -> 
          next err, numberOfRemovedDocs

  startUpload: (fileInfo, next) =>

    @lock fileInfo.media_id, (lockDone) =>
      GridStore.exist @db, fileInfo.media_id, (err, existence) =>
        (lockDone -> return next err) if err?

        now = +new Date
        # New file, set initial chunk size
        unless existence
          mode = 'w'
          options = 
            'content_type'   : fileInfo.contentType          
            metadata :
              instanceLength : fileInfo.instanceLength
              instanceMD5    : fileInfo.instanceMD5
              createDate     : now
              accessDate     : now
              modifyDate     : now

          instanceLength = fileInfo.instanceLength

          if instanceLength > 16 * 1024 * 1024 
            dbChunkSize = 2 * 1024 * 1024  # chunk = 2M when length > 16M
          else if instanceLength > 4 * 1024 * 1024 
            dbChunkSize = 1024 * 1024      # chunk = 1M when 4M < length <= 16M
          else if instanceLength > 1024 * 1024 
            dbChunkSize = 512 * 1024       # chunk = 512K when 1M < length <= 4M
          else if instanceLength > 256 * 1024
            dbChunkSize = 256 * 1024       # chunk = 256K when 256K < length <= 1M
          else
            dbChunkSize = instanceLength   # chunk = length when length <= 256K

          options['chunk_size'] = dbChunkSize
        else
          mode = 'w+'
          options = null

        gridStore = new GridStore(@db, fileInfo.media_id, mode, options)
        
        gridStore.open (err, gridStore) ->
          lockDone ->
            return next err, gridStore
          
  rangeUpload: (fileInfo, gridStore, data, next) =>
    @lock fileInfo.media_id, (lockDone) =>

      gridStore.write data, false, (err, gridStore) ->
        lockDone ->
          return next err if err?
          if gridStore.position >= fileInfo.instanceLength
            gridStore.close (err, uploadResult) ->
              return next err, uploadResult
          else
            return next null, null

  closeUpload: (fileInfo, gridStore, next) =>
    @lock fileInfo.media_id, (lockDone) =>
      gridStore.close (err, uploadResult) ->
        lockDone ->
          return next err, uploadResult

  createReadStream: (media_id, options, next) =>
    @lock media_id, (lockDone) =>

      if arguments.count is 2
        next = options
        options = null

      gridStore = new GridStore(@db, media_id, 'r')
      gridStore.open (err, mediaFile) ->
        lockDone ->
          return next err if err?

          instanceLength = mediaFile.metadata.instanceLength
          if instanceLength? and  instanceLength is mediaFile.length
            stream = new GStream mediaFile, options            
          else
            stream = null
          next null, stream
        
###
# Modulereturn Exports
###
mediaFile = coreClass.get()

callAfterDBConnected = (func, params) ->
  next = params.pop()

  params.push (err, res) ->
    next err, res if next?

  if mediaFile.db.state is 'disconnected'
    mediaFile.db.open (err, db) ->
      return next err if err?

      func.apply module, params
  else
    func.apply module, params

###
module.exports.stat = (media_id, next) ->
  if mediaFile.db.state is 'disconnected'
    mediaFile.db.open (err, db) ->
      return next err if err?

      mediaFile.stat media_id, (err, stats) ->
        return next err, stats if next?
  else
    mediaFile.stat media_id, (err, stats) =>
      return next err, stats if next?
###

module.exports.stat = (media_id, next) ->
  callAfterDBConnected mediaFile.stat, [media_id, next]

module.exports.unlink = (media_id, next) ->
  callAfterDBConnected mediaFile.unlink, [media_id, next]

module.exports.createReadStream = (media_id, options, next) ->
  callAfterDBConnected mediaFile.createReadStream, [media_id, options, next]

module.exports.startUpload = (fileInfo, next) ->
  callAfterDBConnected mediaFile.startUpload, [fileInfo, next]

module.exports.rangeUpload = (fileInfo, gridStore, data, next) ->
  callAfterDBConnected mediaFile.rangeUpload, [fileInfo, gridStore, data, next]

module.exports.closeUpload = (fileInfo, mediaStore, next) ->
  callAfterDBConnected mediaFile.closeUpload, [fileInfo, mediaStore, next]
