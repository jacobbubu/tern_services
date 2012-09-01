Log           = require 'tern.logger'
GetSender     = require('./sender_pool').getDataQueuesSender
MediaFile     = require('../models/media_file_mod')
PJ            = require 'tern.prettyjson'

class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _MemoAgent

class _MemoAgent

  mediaWriteback: (dataZone, memo, next) =>
    # mid is media_id
    try
      mid = memo.mid
      sender = GetSender(dataZone)

      #Log.info 'MediaUriWriteback [send]\r\n-\r\n' + PJ.render memo
      sender.send 'MediaUriWriteback', memo, (err, response) =>
        return next err if err?

        #Log.info 'MediaUriWriteback [back]\r\n-\r\n' + PJ.render response
        
        error = null
        status = response.status

        switch status
          when 200
            # Taking sharing list back (WE HOPE).
            result = response.result
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

module.exports.mediaWriteback = (dataZone, memo, next) =>
  memoAgent.mediaWriteback dataZone, memo, (err) ->
    next err if next?