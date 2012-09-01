Log       = require 'tern.logger'
Receiver  = require('tern.queue').Receiver
Datazones = require 'tern.data_zones'
PJ        = require 'tern.prettyjson'
MediaFile = require '../models/media_file_mod'
ZMQStatusCodes  = require('tern.zmq_helper').zmq_status_codes

class DeleteMedia
  run: (data, next) ->
    #Log.info 'DeleteMedia [recv]\r\n-\r\n' + PJ.render data

    media_id = data.media_id

    MediaFile.unlink media_id, (err, numberOfRemovedMedia) ->
      return next err if next? and err?

      if numberOfRemovedMedia > 0
        response =
          status: ZMQStatusCodes.OK
      else
        response =
          status: ZMQStatusCodes.NotFound

      next null, response if next?

current = Datazones.currentDataZone()
for dataZone, value of Datazones.all()
  mediaQueues = value.mediaQueuesToOtherZones
  if mediaQueues?[current]?
    { host, port } = mediaQueues?[current].dealer.connect
    endpoint = "tcp://#{host}:#{port}"
    receiver = new Receiver { dealer: endpoint }
    receiver.registerWorker 'DeleteMedia', DeleteMedia
    Log.notice "Worker('DeleteMedia') from #{current} to #{dataZone} registered on #{endpoint}"
