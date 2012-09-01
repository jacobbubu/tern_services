###
# Token Model
#   
#   Get Access Token's info then cache it in local db
###

Log           = require('tern.logger')
Err           = require('tern.exceptions')
Checker       = require('tern.param_checker')
DB            = require('tern.database')
Cache         = require('tern.cache')
Utils         = require('tern.utils')
BrokersHelper = require('tern.central_config').BrokersHelper

Sender        = require('tern.zmq_reqres').Sender

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
    @db = DB.getDB 'tokenCacheDB'
    @authSender = null

    # LRU Cache for client, 60s expiration
    @cache = new Cache("tokens", {size: 10, expiry: 60000})


  getInfo: (accessToken, next) =>
    throw new ArgumentNullException "'accessToken' required." unless accessToken?

    # Process cache first
    tokenObject =  @cache.get accessToken    
    return next null, tokenObject if tokenObject?

    message = 
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
      @authSender.send 'TokenAuth', message, (err, response) =>
        return next err if err?
                
        if response.status is 200
          result = response.result

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

internals = 
  configObj   : null
  endpoint    : null

configPath = 'centralAuth/zmq/router/connect'
internals.configObj = BrokersHelper.getConfig(configPath)

if internals.configObj?
  internals.endpoint = BrokersHelper.getEndpointFromConfigValue internals.configObj.value

  internals.configObj.on 'changed', (oldValue, newValue) ->
    newEndpoint = BrokersHelper.getEndpointFromConfigValue newValue
    oldEndpoint = BrokersHelper.getEndpointFromConfigValue oldValue
    Log.info "CentralAuth ZMQ config changed (new: #{newEndPoint} old: #{oldEndpoint})"
    internals.endpoint = newEndpoint
    configInit()
else
  throw new Error 'Config for CentralAuth ZMQ required'

configInit = ->
  authSender = new Sender router: internals.endpoint
  
  tokenCacheModel = coreClass.get()
  tokenCacheModel.authSender.close() if tokenCacheModel.authSender?
  tokenCacheModel.authSender = authSender

configInit()

###
# Module Exports
###
tokenCacheModel = coreClass.get()

module.exports.getInfo = (accessToken, next) =>
  tokenCacheModel.getInfo accessToken, (err, res) ->
    next err, res if next? 
