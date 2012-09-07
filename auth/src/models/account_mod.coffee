Log           = require('tern.logger')
Perf          = require('tern.perf_counter')
Utils         = require('tern.utils')
DB            = require('tern.database')
Checker       = require('tern.param_checker')
Err           = require('tern.exceptions')
Consts        = require('tern.consts')
DataZones     = require('tern.data_zones')
Cache         = require('tern.cache')

Clients       = require './client_mod'
Tokens        = require './token_mod'
DBKeys        = require 'tern.redis_keys'

UserIDPattern = /^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$/
EmailPattern = /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.([a-z]{2}|aero|asia|biz|cat|com|coop|info|int|jobs|mobi|museum|name|net|org|pro|tel|travel|xxx|edu|gov|mil))$/

###
# Redis Database
# User table: 
#   type: HASH
#   key:  users/user_id
#
# Email to user_id
#   type: STRING
#   key:  users/email
#   value: user_id
###

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
    @db = DB.getDB 'accountDB'

    # LRU Cache for accounts, 10s expiration
    # @cache = new Cache("users", {size: 10, expiry: 10000})

  ###
  # methdos
  ###
  delete: (user_id, next) =>
    throw new Err.ArgumentNullException "'user_id' required." if not user_id?

    userKey = DBKeys.AccountKey user_id
    emailBaseKey = DBKeys.EmailToUserIDBaseKey()

    script = """
      local userKey = KEYS[1]
      local emailBaseKey = ARGV[1]..'/'
  
      local email = redis.call('HGET', userKey, 'email')
      if email then
        redis.call('DEL', userKey, emailBaseKey..email)
        return 1
      else
        return 0
      end
    """

    args = [1, userKey, emailBaseKey]
    @db.run_script script, args, (err, res) =>
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

    error = @push_error error, 'user_id', 'REQUIRED' unless user_id?
    error = @push_error error, 'user_id', 'LENGTH'   if not Checker.isLengthIn(user_id, 1, 24)
    error = @push_error error, 'user_id', 'PATTERN'  if not Checker.isMatched(user_id, UserIDPattern)
              
    return error

  isEmail: (id) =>
    Checker.isMatched id, UserIDPattern

    error = @push_error error, 'user_id', 'REQUIRED' unless id?

    unless error?
      if Checker.isMatched(id, EmailPattern)
        error = @push_error error, 'email', 'LENGTH'   if not Checker.isLengthIn(email, 6, 254)
      else
        error = @push_error error, 'user_id', 'LENGTH'   if not Checker.isLengthIn(user_id, 1, 24)
        error = @push_error error, 'user_id', 'PATTERN'  if not Checker.isMatched(user_id, UserIDPattern)

    return error

  validate_email: (email, error) =>

    error = @push_error error, 'email', 'REQUIRED' if Checker.isEmpty(email)
    error = @push_error error, 'email', 'LENGTH'   if not Checker.isLengthIn(email, 6, 254)
    error = @push_error error, 'email', 'PATTERN'  if not Checker.isMatched(email, EmailPattern)
              
    return error

  isEmail: (email) =>
    Checker.isMatched email, EmailPattern

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
    error = @push_error error, 'data_zone', 'UNSUPPORTED' if not DataZones.get(data_zone)?

    return error

  ###
  validate_device_id: (device_id, error) =>

    error = @push_error error, 'device_id', 'LENGTH' if not Checker.isLengthIn(device_id, 0, 64)
    return error
  ###

  prepareDataObject: (user_object) =>
    result = {}

    result.email      = user_object.email.trim().toLowerCase()
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

    userKey = DBKeys.AccountKey user_id
    emailKey = DBKeys.EmailToUserIDKey user_data.email

    script = """
      local userKey = KEYS[1]
      local emailKey = KEYS[2]
      local user_id = ARGV[1]

      local userExists = redis.call('EXISTS', userKey)
      local emailExists = redis.call('EXISTS', emailKey)

      if userExists ~=0 then
        return -1
      end

      if emailExists ~=0 then
        return -2
      end

      local len = #ARGV
      
      for i = 2, len, 2 do
        redis.call('HSET', userKey, ARGV[i], ARGV[i+1])
      end

      redis.call('SET', emailKey, user_id)

      return 0
    """
    # Two keys (user_id & email) with 1 user_id
    args = [2, userKey, emailKey, user_id]

    # Tile an object into array
    for k, v of user_data
      args.push k
      args.push v

    @db.run_script script, args, (err, res) =>
      next err, res

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
      error = @validate_email user_object.email, error      
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
    @save user_object, (err, res) =>
      if err?
        next err, null #Unexpected exception occured, return now
      else
        if res in [-1, -2]
          error = null          
          result.status = -1

          if res is -1
            error = @push_error error, 'user_id', 'EXISTS'
          else
            error = @push_error error, 'email', 'EXISTS'

          result.error = error
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

              Tokens.new user_object.user_id, client_id, scope, user_object.data_zone, client.ttl, (err, tokens) ->                  
                next err, tokens

  unique: (user_object, next) =>

    badArguments = 
      status: -1
      error:
        'user_id': '[REQUIRED_EITHER:user_id:email]'

    try
      return next null, badArguments unless user_object?

      user_id = user_object.user_id      
      email = user_object.email

      if not user_id? and not email?
        return next null, badArguments

      error = null
      if user_id?
        user_id = user_id.toString().trim()  
        error = @validate_user_id user_id, error

      if email?
        email = email.toString().trim().toLowerCase()
        error = @validate_email email, error
      
      if error?
        badArguments.error = error
        return next null, badArguments

    catch e
      next e, null
      return
    
    userKey = if user_id? then DBKeys.AccountKey user_id else ''
    emailKey = if email? then DBKeys.EmailToUserIDKey email else ''
    
    script = """
      local userKey = KEYS[1]
      local emailKey = KEYS[2]

      local result = 0

      if userKey ~= '' then
        if redis.call('EXISTS', userKey) == 1 then
          result = result + 1
        end
      end
      if emailKey ~= '' then
        if redis.call('EXISTS', emailKey) == 1 then
          result = result + 2
        end
      end
      return result
    """
    
    args = [2, userKey, emailKey]
    @db.run_script script, args, (err, res) ->
      if err?
        next err, null
      else
        result = 
          status: 0
          result: {}

        if user_id?
          result.result.user_id = 
            name: user_id
            unique: not (res & 1)

        if email?
          result.result.email = 
            name: email
            unique: not (res & 2)

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

    #---
    authenticateWithUserIDAndClientID = (client_id, user_id, password, next) =>
      Clients.lookup client_id, (err, client) =>
        return next err if err?
          
        if client?
          ttl = client.ttl
          scope = client.scope.join " "

          key = DBKeys.AccountKey user_id

          @db.hmget key, 'password', 'data_zone', (err, result) ->
            return next err if err?        
            
            return next null, { 'status': -4 } unless result?

            passwordHash = result[0]
            data_zone = result[1]
            return next null, { 'status': -4 } unless Utils.verifyPassword(password.trim(), passwordHash)

            Tokens.new user_id, client_id, scope, data_zone, ttl, (err, tokens) ->
              next err, tokens
        else
          next new Error("Invalid client_id ('#{client_id}').")

    #---
    error = null

    id   = user_object.id
    password  = user_object.password

    try
      error = @push_error error, 'id', 'REQUIRED' unless id?
      error = @push_error error, 'password', 'REQUIRED'  if Checker.isEmpty(password)
    catch e
      next e

    return next null, { 'status': -1, 'error': error } if error?

    if @isEmail(id)
      email = id
      error = @validate_email email, error
    else
      user_id = id
      error = @validate_user_id user_id, error
    
    return next null, { 'status': -1, 'error': error } if error?

    if email?
      accountBaseKey = DBKeys.AccountBaseKey()
      emailKey = DBKeys.EmailToUserIDKey email

      script = """
        local emailKey = KEYS[1]
        local accountBaseKey = ARGV[1]..'/'
        local userKey
        local emailVerified
        
        local user_id = redis.call('GET', emailKey)
        if user_id then
          userKey = accountBaseKey..user_id
          emailVerified = redis.call('HGET', userKey, 'email_verified')
          if emailVerified and emailVerified == 'true' then
            return user_id
          else
            return -1
          end
        else
          return -2
        end
      """
      args = [1, emailKey, accountBaseKey]
      @db.run_script script, args, (err, res) =>
        return next err if err?

        if typeof res is 'string'
          # Email has been verified
          user_id = res
          return authenticateWithUserIDAndClientID client_id, user_id, password, next

        if res is -1
          # Has relative user_id but the email has not been verified yet
          return next null, { 'status': -7 }
        else
          # No email exist
          return next null, { 'status': -4 }
    else
      authenticateWithUserIDAndClientID client_id, user_id, password, next

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

exports.unique = (user_object, next) ->
  accountModel.unique user_object, (err, res) ->
    next err, res if next?

exports.refreshToken = (client_id, refreshToken, next) ->
  accountModel.refreshToken client_id, refreshToken, (err, res) ->
    next err, res if next?

exports.renewTokens = (client_id, user_object, next) ->
  accountModel.renewTokens client_id, user_object, (err, res) ->
    next err, res if next?
