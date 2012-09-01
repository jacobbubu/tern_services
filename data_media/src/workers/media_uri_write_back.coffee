Log       = require 'tern.logger'
Receiver  = require('tern.queue').Receiver
Datazones = require 'tern.data_zones'
PJ        = require 'tern.prettyjson'
Memo      = require '../models/memo_mod'
ZMQStatusCodes  = require('tern.zmq_helper').zmq_status_codes

class MediaUriWriteback
  run: (data, next) ->
    #Log.info 'MediaUriWriteback [recv]\r\n-\r\n' + PJ.render data

    Memo.mediaUriWriteback data, (err, res) ->
      return next err if next? and err?

      try        
        result = res[0]

        #  0: Success
        #  1: Has a new version
        # -1: bad argument
        # -3: Not Found
        
        status = result.status
        switch status
          when 1
            response =
              status: ZMQStatusCodes.BadRequest
          when 0
            response =
              status: ZMQStatusCodes.OK
          when -1
            response =
              status: ZMQStatusCodes.BadRequest
          when -3
            response =
              status: ZMQStatusCodes.NotFound

        next null, response if next?
        return

      catch e 
        next e

current = Datazones.currentDataZone()
for dataZone, value of Datazones.all() 
  dataQueues = value.dataQueuesToOtherZones
  if dataQueues?[current]?
    { host, port } = dataQueues?[current].dealer.connect
    endpoint = "tcp://#{host}:#{port}"
    receiver = new Receiver { dealer: endpoint }
    receiver.registerWorker 'MediaUriWriteback', MediaUriWriteback
    Log.notice "Worker('MediaUriWriteback') from #{current} to #{dataZone} registered on #{endpoint}"