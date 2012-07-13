WebSocketClient = require('websocket').client
TestData        = require './test_data'
Log             = require('ternlibs').test_log
WSMessageHelper = require('ternlibs').ws_message_helper
DefaultPorts    = require('ternlibs').default_ports

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
        data = WSMessageHelper.parse message
        data = JSON.parse data

        if data.request? and @pushHandler?
          @pushHandler data.request

        if data.response? and @messageCallback?
          @messageCallback data.response 

      next()

    @options = 
      'authorization'     : "Bearer, " + TestData.access_token
      'accept-language'   : 'zh'
      'x-device-id'       : 'device1'
      'x-compress-method' : 'lzf'

    @client.connect DefaultPorts.DataWS.uri
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

    WSMessageHelper.send @connection, JSON.stringify(req)

module.exports = TernClient