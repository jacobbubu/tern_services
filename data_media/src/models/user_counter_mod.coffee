Log           = require('tern.logger')
Err           = require('tern.exceptions')
DB            = require('tern.database')

###
# Redis Database
# UserCounterTable:
#   type: HASH
#   key:  users/[user_id]/counters/
###
UserCounterTableKey = (user_id) ->
  return ['users', user_id, 'counters'].join '/'

SupportedFolders = ['memo', 'tag', 'comment', 'sharing_roster']
CheckFolderError = (folderName) ->
  unless folderName in SupportedFolders
    return Err.ArgumentUnsupportedException("Unsupported folder name('#{folderName}').")
  else
    return null

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _UserCounterModel

class _UserCounterModel
  constructor: () ->
    @db = null

  getCurrent: (user_id, folderName, next) =>
    
    @db = DB.getDB 'userDBShards', user_id unless @db?

    key = UserCounterTableKey user_id

    if ( err = CheckFolderError(folderName) )?
      return next err

    @db.hget key, folderName, (err, res) =>
      return next err if err?

      if res? 
        res = parseInt(res)
      else res = 0

      res = if res? then parseInt(res) else 0
      next null, res

  increase: (user_id, folderName, increment, next) =>
    
    @db = DB.getDB 'userDBShards', user_id unless @db?

    key = UserCounterTableKey user_id

    if ( err = CheckFolderError(folderName) )?
      return next err

    @db.hincrby key, folderName, increment, (err, res) =>
      next err, res

  delete: (user_id, folderName, next) =>

    @db = DB.getDB 'userDBShards', user_id unless @db?
    
    key = UserCounterTableKey user_id

    if ( err = CheckFolderError(folderName) )?
      return next err

    @db.hdel key, folderName, (err, res) =>
      next err, res

###
# Modulereturn Exports
###
memoModel = coreClass.get()

###
# return:
#   res: new counter number
###
module.exports.getCurrent = (user_id, folderName, next) =>
  memoModel.getCurrent user_id, folderName, (err, res) =>
    next err, res if next? 

module.exports.increase = (user_id, folderName, next) =>
  memoModel.increase user_id, folderName, 1, (err, res) =>
    next err, res if next? 

module.exports.decrease = (user_id, folderName, next) =>
  memoModel.increase user_id, folderName, -1, (err, res) =>
    next err, res if next? 

module.exports.delete = (user_id, folderName, next) =>
  memoModel.delete user_id, folderName, (err, res) =>
    next err, res if next? 
