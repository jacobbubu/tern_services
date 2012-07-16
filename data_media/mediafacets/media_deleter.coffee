MediaFile  = require '../models/media_file_mod'
Assert     = require('assert')
###
  Media delete middleware
###
mediaDeleter = (req, res, next) ->
  Assert.equal req.method, 'DELETE'
  Assert.ok    req._tern
  Assert.ok    req._tern.user_id
  Assert.ok    req._tern.media_id

  MediaFile.unlink req._tern.media_id, (err) ->
    return next err if err?
    
    res.send 200

module.exports = mediaDeleter