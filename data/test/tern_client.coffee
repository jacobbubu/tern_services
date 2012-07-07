WebSocketClient = require('websocket').client
TestData        = require './test_data'
Log             = require './test_log'
MessageHelper   = require '../wsfacets/message_helper'

class TernClient
  constructor: () ->
    @client = new WebSocketClient()
    @connection = null
    @options = null
    @pushHandler = null
    @messageCallback = null

  connect: (next) =>

    @client.on 'connectFailed', (error) =>
      throw new Error("Connection error unexpectly. #{error.toString()}")

    @client.on 'connect', (conn) =>
      @connection = conn
      @connection._tern = 
        compressMethod : @options['x-compress-method']
        device_id      : @options['x-device-id']
        contentLang    : @options['accept-language']

      conn.on 'close', (reasonCode, description) => 
        if reasonCode isnt 1000
          Log.clientError "Connection closed unexpectly. #{reasonCode}: #{description}"

      conn.on 'message', (message) =>
        data = MessageHelper.parse message
        data = JSON.parse data

        if data.request? and @pushHandler?
          @pushHandler data.request

        if data.response? and @messageCallback?
          @messageCallback data.response 

      next()

    @options = 
      'authorization'     : "Bearer, " + TestData.accessToken
      'accept-language'   : 'zh'
      'x-device-id'       : 'device1'
      'x-compress-method' : 'lzf'

    @client.connect "ws://localhost:#{TestData.dataWSPort}/1/websocket"
      , 'data'
      , null
      , @options

  close: (next) =>
    if @connection?
      @connection.close()
      
      setTimeout =>
        if @connection.state is 'closed'
          next()
      , 10

  send: (req, next) =>

    cb = (response) =>
      if (response.method is req.request.method) and (response.req_ts is req.request.req_ts)
        @messageCallback = null
        next response

    # Add callback
    @messageCallback = cb

    MessageHelper.send @connection, JSON.stringify(req)

module.exports = TernClient