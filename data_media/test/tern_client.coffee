WebSocketClient = require('websocket').client
TestData        = require './test_data'
Log             = require('tern.test_utils').test_log
WSMessageHelper = require 'tern.ws_message_helper'
BrokersHelper   = require('tern.central_config').BrokersHelper
DataZones       = require 'tern.data_zones'

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
          return

        if data.response? and @messageCallback?
          @messageCallback data.response 
          return

      next()

    @options = 
      'authorization'     : "Bearer, " + TestData.access_token
      'accept-language'   : 'zh'
      'x-device-id'       : 'device1'
      'x-compress-method' : 'lzf'

    dataZone = DataZones.currentDataZone()
    { host, port } = DataZones.getWebSocketConnect dataZone
    endpoint = "ws://#{host}:#{port}/1/websocket"
    #console.log 'test datamedia endpoint', endpoint

    @client.connect endpoint
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
        next and next response

    # Add callback
    @messageCallback = next

    WSMessageHelper.send @connection, JSON.stringify(req)

module.exports = TernClient