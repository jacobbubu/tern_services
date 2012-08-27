GetSender     = require('./sender_pool').getSender
MediaFile     = require('../models/media_file_mod')

class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _MemoAgent

class _MemoAgent

  mediaWriteback: (data_zone, memo, next) =>
    # mid is media_id
    try
      mid = memo.mid
      sender = GetSender(data_zone)

      message = 
        method: "mediaUriWriteback"
        data: memo

      sender.send message, (err, response) =>
        return next err if err?

        error = null
        status = response.response.status

        switch status
          when 200
            # Taking sharing list back (WE HOPE).
            result = response.response.result
          when 404
            # Delete inexsisting media
            MediaFile.unlink memo.mid, (err) ->
              error = new Error("Error delete media ('#{mid}'): " + err.toString()) if err?
          else
            error =  new Error("Unknown writeback status = #{status} media_id: ('#{mid}')")

        next error

    catch e
      next e

###
# Modulereturn Exports
###
memoAgent = coreClass.get()

module.exports.mediaWriteback = (data_zone, memo, next) =>
  memoAgent.mediaWriteback data_zone, memo, (err) ->
    next err if next?