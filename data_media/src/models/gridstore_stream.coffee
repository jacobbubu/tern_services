Stream = require 'stream'
Chunk  = require('mongodb').Chunk

Chunk.prototype.seek = (pos) ->
  if 0<= pos < this.length()
    this.internalPosition = pos

GridStoreStream = (gstore, options) ->
  return new GridStoreStream(media_id, gstore) unless @ instanceof GridStoreStream
  Stream.call @

  options = options ? {}

  @autoclose = options.autoclose ? true
  start = options.start ? 0
  end = options.end ? gstore.length - 1

  @firstChunkNumber = Math.floor start / gstore.chunkSize
  @firstChunkPos = start - @firstChunkNumber * gstore.chunkSize

  @lastChunkNumber = Math.floor (end + 1) / gstore.chunkSize
  @lastChunkPos = end - @lastChunkNumber * gstore.chunkSize

  @currentChunkNumber = @firstChunkNumber

  #console.log 'firstChunk:', @firstChunkNumber, 'lastChunk:', @lastChunkNumber, 'firstPos:', @firstChunkPos, 'lastPos:', @lastChunkPos

  @gstore = gstore

  @completedLength = 0
  
  @paused = false
  @readable = true
  @pendingChunk = null
  @executing = false

  self = @
  process.nextTick ()->
    self._execute()

GridStoreStream.prototype.__proto__ = Stream.prototype

GridStoreStream.prototype._execute = ->
  return if @paused or not @readable

  gstore = @gstore
  self = @
  # Set that we are executing
  self.executing = true

  first = self.currentChunkNumber is self.firstChunkNumber

  last = false
  if self.currentChunkNumber is self.lastChunkNumber
    self.executing = false
    last = true

  # move currentChunk to firstChunk
  if self.currentChunkNumber isnt gstore.currentChunk.chunkNumber
    gstore._nthChunk self.currentChunkNumber, (err, chunk) ->
      if err?
        self.readable = false
        self.emit "error", err
        self.executing = false
        return

      self.pendingChunk = chunk
      if self.paused is true
        self.executing = false
        return

      gstore.currentChunk = self.pendingChunk
      self._execute()
  else
    if first
      if self.firstChunkPos > 0
        gstore.currentChunk.seek self.firstChunkPos

      if last   # start and end are in the same chunk
        lengthToRead = self.lastChunkPos - self.firstChunkPos + 1
      else
        lengthToRead = gstore.currentChunk.length() - self.firstChunkPos
    else      
      lengthToRead = if last then self.lastChunkPos + 1 else gstore.currentChunk.length()

    data = gstore.currentChunk.readSlice lengthToRead

    if data? and gstore.currentChunk.chunkNumber is self.currentChunkNumber
      self.completedLength += data.length
      self.pendingChunk = null
      self.emit "data", data

    if last
      self.readable = false
      self.emit "end"
      
      if self.autoclose is true
        if gstore.mode[0] is "w"
          gstore.close (err, doc) ->
            return self.emit("error", err) if err?
            
            self.readable = false       
            self.emit "close", doc
        else
          self.readable = false
          self.emit "close"
    else
      self.currentChunkNumber += 1
      gstore._nthChunk self.currentChunkNumber, (err, chunk) ->
        if err?
          self.readable = false
          self.emit "error", err
          self.executing = false
          return

        self.pendingChunk = chunk
        if self.paused is true
          self.executing = false
          return

        gstore.currentChunk = self.pendingChunk
        self._execute()

GridStoreStream.prototype.pause = () ->
  unless @executing
    @paused = true

GridStoreStream.prototype.destroy = () ->
  @readable = false
  #Emit close event
  @emit "close"

GridStoreStream.prototype.resume = () ->
  return unless @paused and @readable
    
  @paused = false
  self = @
  
  process.nextTick () -> 
    self._execute()

exports = module.exports = GridStoreStream