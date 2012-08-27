Mongodb       = require('mongodb').Db
Server        = require('mongodb').Server
GridStore     = require('mongodb').GridStore

BrokersHelper = require('tern.central_config').BrokersHelper

config = null
db = null

BrokersHelper.init ->
  config = BrokersHelper.getConfig('databases/mediaMongo').value
  db = new Mongodb( 'TernMedia', new Server(config.host, config.port) )

callAfterDBConnected = (func, params) ->
  next = params.pop()

  params.push (err, res) ->
    next err, res if next?

  if db.state is 'disconnected'
    db.open (err, db) ->
      return next err if err?

      func.apply module, params
  else
    func.apply module, params

readFile = (media_id, next) ->
  GridStore.read db, media_id, (err, fileData) ->
    next err, fileData

module.exports.readFile = (media_id, next) ->
  callAfterDBConnected readFile, [media_id, next]

