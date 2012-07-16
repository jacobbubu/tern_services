Mongodb   = require('mongodb').Db
Server    = require('mongodb').Server
ObjectID  = require('mongodb').ObjectID
GridStore = require('mongodb').GridStore
Chunk     = require('mongodb').Chunk
Async     = require('async')
Lock      = require('redis-lock')
Client    = require("redis").createClient()
Assert    = require('assert')

Config        = require('ternlibs').config
Log           = require('ternlibs').logger
DefaultPorts  = require('ternlibs').default_ports

Config.setModuleDefaults 'MediaDB', {
  "host": DefaultPorts.MediaDB.host
  "port": DefaultPorts.MediaDB.port
}

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
    @db = new Mongodb( 'TernMedia', new Server(Config.MediaDB.host, Config.MediaDB.port) )

  stat: (media_id, next) =>
    Assert.ok(@db)

    GridStore.exist @db, media_id, (err, existence) =>
      return next err if err?

      return next null, null unless existence

      mediaFile = new GridStore(@db, media_id, 'r')
      mediaFile.open (err, mediaFile) =>
        return next err if err?

        stats = 
          currentLength   : mediaFile.length
          contentType     : mediaFile.contentType
          chunkSize       : mediaFile.chunkSize
          ctime           : mediaFile.uploadDate
          atime           : mediaFile.metadata.accessDate
          mtime           : mediaFile.metadata.modifyDate
          instanceLength  : mediaFile.metadata.instanceLength
          instanceMD5     : mediaFile.metadata.instanceMD5

        next null, stats

  unlink: (media_id, next) =>
    Assert.ok(@db)

    GridStore.unlink @db, media_id, (err, gridStore) ->
      next err

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

module.exports.upload = (media_id, uploadRequest, data, next) ->
  next null, null if next?