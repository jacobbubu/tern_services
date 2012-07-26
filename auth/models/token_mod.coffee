Async           = require "async"
Serializer      = require 'serializer'

Config          = require('ternlibs').config
Log             = require('ternlibs').logger
Perf            = require('ternlibs').perf_counter
Utils           = require('ternlibs').utils
DB              = require('ternlibs').database
Checker         = require('ternlibs').param_checker
Err             = require('ternlibs').exceptions
Cache           = require('ternlibs').cache
ZMQStatusCodes  = require('ternlibs').zmq_status_codes

###
# Consts
###
CODE_LENGTH         = 128

###
# Redis Database
# Access Token table: (for authentication)
#   type: HASH
#   key:  access_tokens/__token__
#     user_id: xxxx
#     scope: "s1 s2 s3"
# 
# user/client/access_token table: (for revoke)
#   type: String
#     __user_id__/__client_id__/access_token : token key
#
# Refresh Token table: (for authentication)
#   type: HASH
#   key:  refresh_tokens/__token__
#     scope: "s1 s2 s3"
# 
# user/client/refresh_token table: (for revoke)
#   type: String
#     __user_id__/__client_id__/refresh_token : token key
###
AccessTokenTableKey = (token) ->
  return ['access_tokens', token].join '/'

UserClientAccessTokenTableKey = (user_id, client_id) ->
  return [user_id, client_id, 'access_token'].join '/'

RefreshTokenTableKey = (token) ->
  return ['refresh_tokens', token].join '/'

UserClientRefreshTokenTableKey = (user_id, client_id) ->
  return [user_id, client_id, 'refresh_token'].join '/'

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _TokenModel

###
# Class Definition
###
class _TokenModel
  constructor: () ->
    @db = DB.getDB 'AccountDB'   # Use the same DB with Accounts

  ###
  # methdos
  ###

  # Create a pair of access_token and refresh_token
  # 
  new: (user_id, client_id, scope, data_zone, ttl, next) =>

    goAhead = false
    finalResult = null

    fn = (next) =>
      try
        accessToken   = Serializer.randomString CODE_LENGTH
        refreshToken  = Serializer.randomString CODE_LENGTH

        accessTokenKey            = AccessTokenTableKey accessToken
        userClientAccessTokenKey  = UserClientAccessTokenTableKey user_id, client_id
        refreshTokenKey           = RefreshTokenTableKey refreshToken
        userClientRefreshTokenKey = UserClientRefreshTokenTableKey user_id, client_id

        # store the expiration(in seconds) of access_token
        expires_at                = Math.floor( (new Date) / 1000 ) + parseInt(ttl)
      catch e
        next e

      # return
      #  0: success
      #  1: token exists, re-generate needed
      script = """        
        local accessTokenKey            = KEYS[1]
        local userClientAccessTokenKey  = KEYS[2]
        local refreshTokenKey           = KEYS[3]
        local userClientRefreshTokenKey = KEYS[4]
        local user_id                   = ARGV[1]
        local client_id                 = ARGV[2]
        local scope                     = ARGV[3]
        local data_zone                 = ARGV[4]
        local expires_at                = ARGV[5]

        local exist = redis.call('EXISTS', accessTokenKey)
        if exist == 1 then
          return 1
        end
        exist = redis.call('EXISTS', refreshTokenKey)
        if exist == 1 then
          return 1
        end
        local oldKey = redis.call('GETSET', userClientAccessTokenKey, accessTokenKey)
        if oldKey then
          redis.call('DEL', oldKey)  
        end
        oldKey = redis.call('GETSET', userClientRefreshTokenKey, refreshTokenKey)
        if oldKey then
          redis.call('DEL', oldKey)  
        end
        redis.call('HMSET', accessTokenKey, 'user_id', user_id, 'client_id', client_id, 'data_zone', data_zone, 'expires_at', expires_at, 'scope', scope)
        redis.call('HMSET', refreshTokenKey, 'user_id', user_id, 'client_id', client_id, 'data_zone', data_zone, 'scope', scope)
        redis.call('EXPIREAT', accessTokenKey, expires_at)
        return 0
      """
      
      @db.run_script script
        , 4                             # 4 keys
        , accessTokenKey                # KEYS[1]
        , userClientAccessTokenKey      # KEYS[2]
        , refreshTokenKey               # KEYS[3]
        , userClientRefreshTokenKey     # KEYS[4]
        , user_id                       # ARGV[1]
        , client_id                     # ARGV[2]
        , scope                         # ARGV[3]
        , data_zone                     # ARGV[4]
        , expires_at                    # ARGV[5]
        , (err, result) ->
          if err?
            next err
          else
            switch result
              when 0
                goAhead = true
                finalResult = 
                  'status'        : 0
                  'result'        :
                    'access_token'  : accessToken
                    'refresh_token' : refreshToken
                    'token_type'    : "bearer"
                    'expires_in'    : ttl
                next null
              when 1
                next null

    Async.whilst(
        () -> return (goAhead is false)
      , fn
      , (err) ->
        if err?
          next err, null
        else
          next null, finalResult
    )

  # Generate a new access_token from old refreshToken
  #
  refresh: (client_id, refreshToken, ttl, next) =>

    goAhead = false
    finalResult = null
    
    fn = (next) =>
      try
        accessToken   = Serializer.randomString CODE_LENGTH

        accessTokenKey            = AccessTokenTableKey accessToken
        refreshTokenKey           = RefreshTokenTableKey refreshToken

        # store the expiration(in milliseconds) of that access_token
        expires_at                = Math.floor( (new Date).getTime() / 1000 ) + parseInt(ttl)
      catch e
        next e

      # return
      #   0: Success
      #   1: token exists, re-generate needed
      #  -1: Unmatched client_id
      #  -2: Invalid refresh token
      script = """
        local accessTokenKey            = KEYS[1]
        local refreshTokenKey           = ARGV[1]
        local client_id                 = ARGV[2]
        local expires_at                = ARGV[3]

        local exist = redis.call('EXISTS', accessTokenKey)
        if exist == 1 then
          return 1
        end
        exist = redis.call('EXISTS', refreshTokenKey)
        if exist == 0 then
          return -1
        end
        local oldClientId = redis.call('HGET', refreshTokenKey, 'client_id')
        if oldClientId ~= client_id then
          return -1
        end
        local user_id   = redis.call('HGET', refreshTokenKey, 'user_id')
        local scope     = redis.call('HGET', refreshTokenKey, 'scope')
        local data_zone = redis.call('HGET', refreshTokenKey, 'data_zone')

        local userClientAccessTokenKey  = user_id.."/"..client_id.."/".."access_token"

        local oldKey = redis.call('GETSET', userClientAccessTokenKey, accessTokenKey)
        if oldKey then
          redis.call('DEL', oldKey)  
        end
        redis.call('HMSET', accessTokenKey, 'user_id', user_id, 'client_id', client_id, 'data_zone', data_zone, 'expires_at', expires_at, 'scope', scope)
        redis.call('EXPIREAT', accessTokenKey, expires_at)
        return 0        
      """
    
      @db.run_script script
        , 1                             # 1 keys
        , accessTokenKey                # KEYS[1]
        , refreshTokenKey               # ARGV[1]
        , client_id                     # ARGV[2]
        , expires_at                    # ARGV[3]
        , (err, result) ->
          return next err if err?
          
          switch result
            when 0
              goAhead = true
              finalResult = 
                'status'        : 0
                'result'        :
                  'access_token'  : accessToken
                  'refresh_token' : refreshToken
                  'token_type'    : "bearer"
                  'expires_in'    : ttl
              next null
            when 1
              next null
            when -1, -2
              goAhead = true
              finalResult = { 'status': -3}
              next null

    Async.whilst(
        () -> return (goAhead is false)
      , fn
      , (err) ->
        if err?
          next err, null
        else
          next null, finalResult
    )

  # return
  #   0: Success
  #  -2: Invalid access token  
  tokenAuth: (accessToken, next) =>

    accessTokenKey = AccessTokenTableKey accessToken 

    @db.hgetall accessTokenKey, (err, tokenInfo) ->
      if err?
        next err
      else
        if tokenInfo?
          response =
            status: ZMQStatusCodes.OK
            result:
              access_token: accessToken
              user_id     : tokenInfo.user_id
              client_id   : tokenInfo.client_id
              scope       : tokenInfo.scope
              data_zone   : tokenInfo.data_zone
              expires_in  : Math.round ( +tokenInfo.expires_at - (new Date) / 1000 )
          next null, response
        else
          response =
            status: ZMQStatusCodes.NotFound
          next null, response

###
# Module Exports
###
tokenModel = coreClass.get()

module.exports.new = (user_id, client_id, scope, data_zone, ttl, next) ->
  tokenModel.new user_id, client_id, scope, data_zone, ttl, (err, res) ->
    next err, res if next?

module.exports.refresh = (client_id, refreshToken, ttl, next) ->
  tokenModel.refresh client_id, refreshToken, ttl, (err, res) ->
    next err, res if next?

###
module.exports.getToken = (user_id, client_id, scope, ttl, next) ->
  tokenModel.getToken user_id, client_id, scope, ttl, (err, res) ->
    next err, res if next?
###

module.exports.tokenAuth = (accessToken, next) ->
  tokenModel.tokenAuth accessToken, (err, res) ->
    next err, res if next?

