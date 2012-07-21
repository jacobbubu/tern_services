Mongodb   = require('mongodb').Db
Server    = require('mongodb').Server
GridStore = require('mongodb').GridStore

Config        = require('ternlibs').config
DefaultPorts  = require('ternlibs').default_ports

Config.setModuleDefaults 'MediaDB', {
  "host": DefaultPorts.MediaDB.host
  "port": DefaultPorts.MediaDB.port
}

db = new Mongodb( 'TernMedia', new Server(Config.MediaDB.host, Config.MediaDB.port) )

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

