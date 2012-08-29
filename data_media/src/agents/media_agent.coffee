GetSender     = require('./sender_pool').getMediaQueuesSender

class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _MediaAgent

class _MediaAgent

  deleteMedia: (media_zone, media_id, next) =>
    # mid is media_id
    try
      sender = GetSender(media_zone)

      data = 
        media_id: media_id

      sender.send 'DeleteMedia', data, (err, res) =>
        return next err if err?
        next null, res
    catch e
      next e

###
# Modulereturn Exports
###
mediaAgent = coreClass.get()

module.exports.deleteMedia = (media_zone, media_id, next) =>
  mediaAgent.deleteMedia media_zone, media_id, (err, res) ->
    next err, res if next?
