###
# Token Model
#   
#   Get Access Token's info then cache it in local db
###

Config        = require('ternlibs').config
Log           = require('ternlibs').logger
Err           = require('ternlibs').exceptions
Checker       = require('ternlibs').param_checker
DB            = require('ternlibs').database
Cache         = require('ternlibs').cache
Utils         = require('ternlibs').utils

ZMQSender     = require('ternlibs').ZMQSender
DefaultPorts  = require('ternlibs').default_ports

###
# Redis Database
# TokenCacheTable:
#   type: HASH
#   key:  token_cache/accessToken# 
###
TokenCacheTableKey = (accessToken) ->
  return Utils.pathJoin( "token_cache", accessToken )


# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _TokenModel

class _TokenModel
  constructor: () ->
    @db = DB.getDB 'TokenCacheDB'
    @authSender = null

    # LRU Cache for client, 60s expiration
    @cache = new Cache("tokens", {size: 10, expiry: 60000})


  getInfo: (accessToken, next) =>
    throw new ArgumentNullException "'accessToken' required." unless accessToken?

    # Process cache first
    tokenObject =  @cache.get accessToken
    return next null, tokenObject if tokenObject?

    message = 
      method: "tokenAuth"
      data:
        access_token: accessToken

    key = TokenCacheTableKey accessToken

    # Then current zone's db
    @db.hgetall key, (err, tokenObject) =>
      return next err if err?
      
      if tokenObject?
        tokenObject.scope = tokenObject.scope.split /\s+/
        @cache.set accessToken, tokenObject
        return next null, tokenObject 
      
      # Finally, call remote service
      @authSender.send message, (err, response) =>
        return next err if err?
                
        if response.response.status is 0
          result = response.response.result

          tokenObject = 
            access_token  : result.access_token
            user_id       : result.user_id
            scope         : result.scope
            data_zone     : result.data_zone
            expire_at     : +new Date + result.expires_in * 1000

          @db.multi()
            .hmset(key, tokenObject)
            .expire(key, result.expires_in) 
            .exec (err, replies) =>            
              return next err if err?

              tokenObject.scope = result.scope.split /\s+/   # convert scope string to array ('a b c' -> ['a', 'b', 'c'])

              # Save to current process cache
              @cache.set accessToken, tokenObject

              next null, tokenObject
        else
          err = Err.ResourceDoesNotExistException("Access Token(#{accessToken}) does not exist.")
          return next err

###
# Configuration
# This configuration could take effect on the fly
#
# host: address of Central Auth. Service (ZMQ Req/Res)
# port: port of Central Auth. Service
#
###
Config.setModuleDefaults 'CentralAuth', {
  "host": DefaultPorts.CentralAuthZMQ.host
  "port": DefaultPorts.CentralAuthZMQ.port
}

# Set config file change monitor
Config.watch Config, 'CentralAuth', (object, propertyName, priorValue, newValue) ->
  Log.info "CentralAuth config changed: '#{propertyName}' changed from '#{priorValue}' to '#{newValue}'"
  configInit()

configInit = ->
  config = Config.CentralAuth
  authSender = new ZMQSender("tcp://#{config.host}:#{config.port}")
  
  tokenCacheModel = coreClass.get()
  tokenCacheModel.authSender = authSender

configInit()


###
# Module Exports
###
tokenCacheModel = coreClass.get()

module.exports.getInfo = (accessToken, next) =>
  tokenCacheModel.getInfo accessToken, (err, res) ->
    next err, res if next? 
