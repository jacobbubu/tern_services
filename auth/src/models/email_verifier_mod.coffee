uuid     = require "node-uuid"
DB       = require('tern.database')
DBKeys   = require 'tern.redis_keys'

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _EmailVerifierModel

###
# Class Definition
###
class _EmailVerifierModel
  constructor: () ->
    @db = DB.getDB 'emailTokenDB'


  generateToken: (user_object, next) =>
    newToken = uuid()
    newTokenValue = JSON.stringify user_object

    emailToTokenKey = DBKeys.EmailToTokenKey user_object.email
    tokenToUserObjKey = DBKeys.EmailTokenToUserObjKey newToken

    script = """
      local emailToTokenKey = KEYS[1]
      local tokenToUserObjKey = KEYS[2]
      local tokenToUserObjKeyBase = ARGV[1]..'/'
      local newToken = ARGV[2]
      local newTokenValue = ARGV[3]

      local tokenKey = redis.call('GET', emailToTokenKey)
      if tokenKey then
        redis.call('DEL', tokenToUserObjKeyBase..tokenKey)        
      end

      redis.call('SETEX', tokenToUserObjKey, 86400, newTokenValue)
      redis.call('SETEX', emailToTokenKey, 86400, newToken)
      return 0
    """

    args = [ 2, emailToTokenKey, tokenToUserObjKey
          , DBKeys.EmailTokenToUserObjKeyBase()
          , newToken
          , newTokenValue]

    @db.run_script script, args, (err, res) =>
      return next err if err?
      next null, newToken

  verifyToken: (token, next) ->

###
# Module Exports
###
emailVerifierModel = coreClass.get()

module.exports.generateToken = (user_id, next) =>
  emailVerifierModel.generateToken user_id, (err, res) ->
    next err, res if next?
