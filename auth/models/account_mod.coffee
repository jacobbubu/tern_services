Config        = require('ternlibs').config
Log           = require('ternlibs').logger
Perf          = require('ternlibs').perf_counter
Utils         = require('ternlibs').utils
DB            = require('ternlibs').database
Checker       = require('ternlibs').param_checker
Err           = require('ternlibs').exceptions
Consts        = require('ternlibs').consts
Cache         = require('ternlibs').cache

Clients       = require './client_mod'
Tokens        = require './token_mod'

###
# Redis Database
# User table: 
#   type: HASH
#   key:  users/user_id
# 
###
UserTableKey = (user_id) ->
  return "users/-PLACEHOLDER-".replace '-PLACEHOLDER-', user_id

# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _AccountModel

###
# Class Definition
###
class _AccountModel
  constructor: () ->
    @db = DB.getDB 'AccountDB'

    # LRU Cache for accounts, 10s expiration
    # @cache = new Cache("users", {size: 10, expiry: 10000})

  ###
  # methdos
  ###
  delete: (user_id, next) =>
    throw new Err.ArgumentNullException "'user_id' required." if not user_id?

    key = UserTableKey user_id
    @db.del_keys key, (err, res) ->
      next err, res

  validate_client: (client_id, client_secret, next) =>
    
    if Checker.isEmpty client_id
      next new Err.ArgumentsNullException "client_id required", null
      return

    if Checker.isEmpty client_secret
      next new Err.ArgumentsNullException "client_secret required", null
      return

    Clients.authenticate client_id, client_secret, (err, authed) ->
      next err, authed

  push_error: (error, field, value) ->
    error = {} if not error?
    error[field] = [] if not error[field]?
    error[field].push value
    return error

  validate_user_id: (user_id, error) =>

    error = @push_error error, 'user_id', 'REQUIRED' if Checker.isEmpty(user_id)
    error = @push_error error, 'user_id', 'LENGTH'   if not Checker.isLengthIn(user_id, 4, 24)
    error = @push_error error, 'user_id', 'PATTERN'  if not Checker.isMatched(user_id, /^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$/)
              
    return error

  validate_password: (password, error) =>

    error = @push_error error, 'password', 'REQUIRED'  if Checker.isEmpty(password)
    error = @push_error error, 'password', 'LENGTH'    if not Checker.isLengthIn(password, 6, 24)
    error = @push_error error, 'password', 'DIGIT'     if not Checker.isMatched(password, /[0-9]+/)
    error = @push_error error, 'password', 'CAPITAL'   if not Checker.isMatched(password, /[A-Z]+/)
    error = @push_error error, 'password', 'LOWERCASE' if not Checker.isMatched(password, /[a-z]+/)

    return error

  splitLocale: (loc) ->
    arr = loc.match /[a-z]+/gi
    
    switch arr.length
      when 1 
        lang = arr[0].toLowerCase()
      when 2
        lang = arr[0].toLowerCase()
        region = arr[1].toUpperCase()
      when 3
        lang = arr[0].toLowerCase()
        script = arr[1].toLowerCase()
        region = arr[2].toUpperCase()

    return [lang, script, region]

  validate_locale: (locale, error) =>

    error = @push_error error, 'locale', 'REQUIRED'  if Checker.isEmpty(locale)
    [lang, script, region] = @splitLocale locale

    # locale and country are MUST have
    error = @push_error error, 'locale', 'LANG'     if not Consts.languages[lang]?
    error = @push_error error, 'locale', 'REGION'   if not Consts.countries[region]?
    # script is optional, but need to check consistence
    error = @push_error error, 'locale', 'SCRIPT'   if script? and not Consts.lang_scripts[script]?

    return error

  validate_data_zone: (data_zone, error) =>

    error = @push_error error, 'data_zone', 'REQUIRED'    if Checker.isEmpty(data_zone)
    error = @push_error error, 'data_zone', 'LENGTH'      if not Checker.isLengthIn(data_zone, 0, 64)
    error = @push_error error, 'data_zone', 'UNSUPPORTED' if not Consts.data_zones[data_zone]?

    return error

  ###
  validate_device_id: (device_id, error) =>

    error = @push_error error, 'device_id', 'LENGTH' if not Checker.isLengthIn(device_id, 0, 64)
    return error
  ###

  prepareDataObject: (user_object) =>
    result = {}
    # Hashed password
    result.password   = Utils.passwordHash user_object.password.trim()
    
    ###
    if user_object.device_id?
      result.device_id  = user_object.device_id.trim()
    else
      result.device_id  = ""
    ###

    result.data_zone  = user_object.data_zone.trim()
    result.locale     = user_object.locale.trim() if user_object.locale?

    [lang, script, region] = @splitLocale user_object.locale

    result.region       = region                                if region?
    result.currency     = Consts.country_info[region].currency  if region?
    result.lang         = lang                                  if lang?
    result.lang_script  = script                                if script?
        
    result.create_at  = (new Date).toISOString()
    return result 

  save: (user_object, next) => 
    user_id   = user_object.user_id.trim()    
    user_data = @prepareDataObject user_object

    key = UserTableKey user_id

    script = """
      local exist = redis.call('EXISTS', KEYS[1])
      if exist == 0 then
        local len = #ARGV
        
        for i = 1, len, 2 do
          redis.call('HSET', KEYS[1], ARGV[i], ARGV[i+1])
        end

        return 0
      else
        return 1
      end
    """
    args = [1, key]
    for k, v of user_data
      args.push k
      args.push v

    @db.run_script script, args, (err, exist) =>
      if err?
        next err, null
      else
        next null, exist is 1

  ###
  # signup: create a new user
  # 
  # return:
  #   status =  0 -SUCCEEDED
  #   status = -1 -BAD ARGUMENTS, error object includes the detail
  #   status = -2 -user_id exists already
  #   status = -3 -Client authentication failed
  ###
  signup: (client_id, user_object, next) =>
    result = {}
    result.status = 0

    error = null

    try
      error = @validate_user_id user_object.user_id, error
      error = @validate_password user_object.password, error

      # Password can not as same as user_id
      if user_object.user_id? and user_object.password? and user_object.user_id.trim() is user_object.password.trim()
        error = @push_error error, 'password', 'SAME_AS_USER_ID'

      error = @validate_locale user_object.locale, error
      error = @validate_data_zone user_object.data_zone, error
      #error = @validate_device_id user_object.device_id, error if user_object.device_id?
    catch e
      next e

    return next null, { 'status': -1, 'error': error } if error?

    # No error, save to database
    @save user_object, (err, exist) =>
      if err?
        next err, null #Unexpected exception occured, return now
      else
        if exist
          result.status = -2
          next null, result
        else
          Clients.lookup client_id, (err, client) ->
            if err?
              next err, null
            else
              if client.scope?
                scope = client.scope.join ' '
              else
                scope = ''

              Tokens.new user_object.user_id, client_id, scope, client.ttl, (err, tokens) ->                  
                next err, tokens

  unique: (user_id, next) =>
    result = 
      status: 0
      result: false

    try      
      if Checker.isEmpty user_id
        next null, result
        return
      user_id = user_id.toString()
    catch e
      next e, null
      return
    
    key = UserTableKey user_id
    
    @db.exists key, (err, res) ->
      if err?
        next err, null
      else
        result.result = res is 0
        next null, result

  refreshToken: (client_id, refreshToken, next) ->

    Clients.lookup client_id, (err, client) ->
      return next err if err?
        
      if client?
        ttl = client.ttl        
        Tokens.refresh client_id, refreshToken, ttl, (err, tokens) ->
          next err, tokens
      else
        next new Error("Invalid client_id ('#{client_id}').")

  renewTokens: (client_id, user_object, next) =>

    error = null

    user_id   = user_object.user_id
    password  = user_object.password

    try
      error = @push_error error, 'user_id', 'REQUIRED' if Checker.isEmpty(user_id)
      error = @push_error error, 'password', 'REQUIRED'  if Checker.isEmpty(password)
    catch e
      next e
    
    return next null, { 'status': -1, 'error': error } if error?

    Clients.lookup client_id, (err, client) =>
      return next err if err?
        
      if client?
        ttl = client.ttl
        scope = client.scope.join " "

        key           = UserTableKey user_id

        @db.hget key, 'password', (err, passwordHash) ->
          return next err if err?        

          return next null, { 'status': -4 } unless passwordHash?

          return next null, { 'status': -4 } unless Utils.verifyPassword(password.trim(), passwordHash)

          Tokens.new user_id, client_id, scope, ttl, (err, tokens) ->
            next err, tokens
      else
        next new Error("Invalid client_id ('#{client_id}').")



###
# Module Exports
###
accountModel = coreClass.get()

module.exports.delete = (user_id, next) =>
  accountModel.delete user_id, (err, res) ->
    next err, res if next?

exports.signup = (client_id, user_object, next) ->
  accountModel.signup client_id, user_object, (err, res) ->
    next err, res if next?

exports.unique = (user_id, next) ->
  accountModel.unique user_id, (err, res) ->
    next err, res if next?

exports.refreshToken = (client_id, refreshToken, next) ->
  accountModel.refreshToken client_id, refreshToken, (err, res) ->
    next err, res if next?

exports.renewTokens = (client_id, user_object, next) ->
  accountModel.renewTokens client_id, user_object, (err, res) ->
    next err, res if next?
