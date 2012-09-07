zmq    = require 'zmq'
Config = require './config'
Utils  = require './utils'

type = (obj) ->
  if obj == undefined or obj == null
    return String obj

  classToType = new Object
  for name in "Boolean Number String Function Array Date RegExp".split(" ")
    classToType["[object " + name + "]"] = name.toLowerCase()

  myClass = Object.prototype.toString.call obj
  if myClass of classToType
    return classToType[myClass]

  return "object"

clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj
  
  switch type(obj)
    when 'date'
      return new Date(obj.getTime())
    when 'regexp'
      flags = '' + (obj.global ? 'g' : '') + (obj.ignoreCase ? 'i' : '') + (obj.multiline ? 'm' : '') + (obj.sticky ? 'y' : '')
      return new RegExp(obj.source, flags)

  newInstance = new obj.constructor()
  for own key of obj
    newInstance[key] = clone obj[key]
  return newInstance

normalizePath = (path) ->
  properties = path.split '/'
  arr = (prop for prop in properties when prop.length > 0)
  arr.join '/'

findNode = (obj, path) ->
  properties = path.split '/'
  node = obj

  for prop in properties
    if prop.length > 0
      node = node[prop]
      if typeof(node) is 'undefined'
        throw new Error("Invalid path('#{path}') in the object")
  node

class Broker
  constructor: ( @options = {} ) ->
    @allConfigs = {}
    @centralConfigObj = null
    @initCallback = null
    @_connect()

  _connect: ->
    @requester  = zmq.socket "req"
    @requester.on "message", @_reqResponse
    @requester.connect @options.requester or "ipc:///tmp/configServer-req"

    @subscriber = zmq.socket "sub"
    @subscriber.on "message", @_subResponse
    @subscriber.connect @options.subscriber or "ipc:///tmp/configServer-sub"
    @subscriber.subscribe 'config'

  # Config request response
  _reqResponse: (payload) =>
    message = payload.toString()
    try
      @centralConfigObj = JSON.parse message
    catch err
      console.error 'Bad config data returned by server: #{message}'
      throw err

  # Config publication receiver
  _subResponse: (payload) =>
    temp = payload.toString()
    pos = temp.indexOf ' '
    if pos is -1
      console.error "Bad config data published by server: #{temp}"
    else
      try
        newConfigObj = JSON.parse temp.slice pos              
      catch err
        console.error "Bad config data published by server: #{temp}"

      @_checkAllConfigs newConfigObj
      @centralConfigObj = newConfigObj

  _checkAllConfigs: (newConfigObj) =>
    for path, config of @allConfigs
      try        
        newConfigNode = findNode newConfigObj, path        
      catch err
        console.error "Invalid config path(#{path}) in new configuration"
        continue

      oldConfigNode = findNode @centralConfigObj, path

      unless Utils.deepEquals newConfigNode, oldConfigNode
        config.emit 'changed', oldConfigNode, newConfigNode unless config.listeners("changed").length is 0

  _fillConfig: (config, path) ->
    configNode = findNode @centralConfigObj, path
    config.value = configNode
    #config.value = clone configNode

  _waitForInit: =>
    if @centralConfigObj?
      @initCallback? and @initCallback null, @centralConfigObj
    else
      process.nextTick @_waitForInit

  init: (next) =>
    @initCallback = next
    unless @centralConfigObj?
      @requester.send 'getConfig'
      process.nextTick @_waitForInit
    else
      next? and next null, @centralConfigObj
  
  getConfig: (path) ->
    new TypeError('Config path required.') unless path?
    unless @centralConfigObj?
      throw new Error('should call init() first')

    path = normalizePath path

    config = @allConfigs[path]
    unless config?
      config = new Config(path)      
      @_fillConfig config, path
      @allConfigs[path] = config

    config
  
module.exports = Broker