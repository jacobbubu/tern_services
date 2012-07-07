Async         = require "async"

Config        = require('ternlibs').config
Log           = require('ternlibs').logger
Perf          = require('ternlibs').perf_counter
Utils         = require('ternlibs').utils
DB            = require('ternlibs').database
Checker       = require('ternlibs').param_checker
Err           = require('ternlibs').exceptions
Consts        = require('ternlibs').consts
Cache         = require('ternlibs').cache

###
# Consts
###
ID_PREFIX   = '3rd:'
CODE_LENGTH = 128
LONG_TTL    = 10 * 365 * 24 * 3600    # seconds for 10 years
SHORT_TTL   = 24 * 3600               # seconds for 24 hours

###
# Redis Database
# Client table: 
#   type: HASH
#   key:  clients/client_id
# 
# Client scope table
#   type: SET
#   key:  clients/client_id/scope
###
ClientTableKey = (client_id) ->
  return "clients/-PLACEHOLDER-".replace '-PLACEHOLDER-', client_id

ClientScopeTableKey = (client_id) ->
  return "clients/-PLACEHOLDER-/scope".replace '-PLACEHOLDER-', client_id


# coreClass, it's a Singleton fetcher
class coreClass
  _instance = undefined
  @get: () ->
    _instance ?= new _ClientModel

###
# Class Definition
###
class _ClientModel
  constructor: () ->
    @db = DB.getDB 'ClientDB'

    # LRU Cache for client, 60s expiration
    @cache = new Cache("clients", {size: 10, expiry: 60000})

  stockClients: 
    'tern_iPhone': 
      secret          : 'Ob-Kp_rWpnHbQ0h059uvJX'
      grant_type      : 'password'
      scope           : ["addMemo", "delMemo"]
      ttl             : LONG_TTL
      pre_defined     : 1
    'tern_iPad': 
      secret          : 'T3u_mR4v-GuorQPHSrvv1R'
      grant_type      : 'password'
      scope           : []
      ttl             : LONG_TTL
      pre_defined     : 1
    'tern_osx': 
      secret          : 'zWsqh7jz74GqO3Rpzatfcd'
      grant_type      : 'password'
      scope           : []
      ttl             : LONG_TTL
      pre_defined     : 1
    'tern_web': 
      secret          : 'jUegvKSb5NYNCFhrWGrnb3'
      grant_type      : 'password'
      scope           : []
      ttl             : LONG_TTL
      pre_defined     : 1
    '3rd:4Wrc9SdnbQmlDKuKxE02XV':    #For test purpose only, do not delete it
      secret          : '1MSTBaANwd8hcTVkLxx0d1'
      grant_type      : 'code'
      scope           : []
      ttl             : SHORT_TTL
      pre_defined     : 1
      redirect_uri    : 'http://localhost:3000/'
      suspended       : 0

  ###
  # methdos
  ###
  clearAll: (next) =>
    @db.del_keys "clients/*", (err, res) ->
      next err, res

  save: (client, next) =>
    client_id = Object.keys(client)[0]
    data = Utils.clone client[client_id]
    
    scope = data.scope ? []
    delete data.scope

    key = ClientTableKey client_id
    scopeKey = ClientScopeTableKey client_id

    script = """
      local exist = redis.call('EXISTS', KEYS[1])
      if exist == 0 then
        local len = #ARGV
        
        for i = 1, len-1, 2 do
          redis.call('HSET', KEYS[1], ARGV[i], ARGV[i+1])
        end

        local scope = ARGV[len]
        for s in string.gmatch(scope, "[^%s]+") do 
          redis.call('SADD', KEYS[2], s)
        end

        return 0
      else
        return 1
      end
    """
    args = [2, key, scopeKey]
    for k, v of data
      args.push k
      args.push v

    args.push scope.join ' '

    @db.run_script script, args, (err, exist) =>
      if err?
        next err, null
      else
        next null, exist is 1

  populate: (next) ->
    clientArr = []
    for c, v of @stockClients
      obj = new Object; obj[c] = v
      clientArr.push obj

    Async.map  clientArr, @save, (err, res) ->
      next err, res if next?


  lookup: (client_id, next) =>
    throw new ArgumentNullException "'client_id' required." if not client_id?

    key = ClientTableKey client_id
    scopeKey = ClientScopeTableKey client_id

    script = """
      return {redis.call('HGETALL', KEYS[1]), redis.call('SMEMBERS', KEYS[2])}    
    """

    # Cache checking first
    client =  @cache.get client_id
    if client?
      next null, client
    else
      @db.run_script script, 2, key, scopeKey, (err, res) =>
        if err? 
          next err 
        else
          if res[0].length > 0
            client = { client_id: client_id}
            client[v] = res[0][i+1] for v, i in res[0] by 2   #clients/client_id
            client.ttl = parseInt(client.ttl)
            client.scope = res[1] if res[1]?

            # Save to cache
            @cache.set client_id, client

            next null, client
          else
            next null, null

  authenticate: (client_id, client_secret, next) => 
    throw new ArgumentNullException "'client_id' required."     if not client_id?
    throw new ArgumentNullException "'client_secret' required." if not client_secret?

    key = ClientTableKey client_id

    # Cache checking first
    client =  @cache.get client_id
    if client?
      next null, client.secret is client_secret
    else
      @lookup client_id, (err, client) =>
        if err? 
          next err 
        else
          if client?
            next null, client.secret is client_secret
          else
            next null, false

  setSuspended: (client_id, suspended, next) =>
    throw new ArgumentNullException "'client_id' required." if not client_id?
    throw new TypeError "Type of 'suspended' should be boolean" if typeof(suspended) isnt 'boolean'

    key = ClientTableKey client_id
    script = """
      local result
      local exist = redis.call('EXISTS', KEYS[1])
      if exist == 0 then 
        result = nil
      else 
        result = redis.call('HGET', KEYS[1], 'suspended')
        if result == nil then 
          result = '0'
        end
        redis.call('HSET', KEYS[1], 'suspended', ARGV[1]);
      end
      return result
    """

    value = 0
    value = 1 if suspended
    # res is the old value
    @db.run_script script, 1, key, value, (err, oldValue) =>
      if err?
        next err, null
      else
        # data changed, so delete th cache item
        @cache.del client_id

        next null, oldValue

###
# Configuration
###
Config.setModuleDefaults 'ClientModel', {
  "tern_iPhone": 
    ttl: 10 * 365 * 24 * 3600    # seconds for 10 years
  "default":
    ttl: 24 * 3600               # seconds for 24 hours
    grant_type: 'code'
}

# Set config file change monitor
Config.watch Config, 'ClientModel', (object, propertyName, priorValue, newValue) ->
  Log.info "ClientModel config changed: '#{propertyName}' changed from '#{priorValue}' to '#{newValue}'"
  configInit()

configInit = ->
  clientModel = coreClass.get()

  config = Config.ClientModel
  clients = clientModel.stockClients

  clientModel.default_ttl        = config["default"].ttl        if config["default"]?.ttl?
  clientModel.default_grant_type = config["default"].grant_type if config["default"]?.grant_type?

configInit()

###
# Module Exports
###
clientModel = coreClass.get()

module.exports.clearAll = (next) =>
  clientModel.clearAll (err, res) ->
    next err, res if next? 

module.exports.populate = (next) =>
  clientModel.populate (err, res) ->
    next err, res if next? 

module.exports.lookup = (client_id, next) =>
  clientModel.lookup client_id, (err, res) ->
    next err, res if next? 

module.exports.authenticate = (client_id, client_secret, next) =>
  clientModel.authenticate client_id, client_secret, (err, res) ->
    next err, res if next? 

module.exports.resume = (client_id, next) =>
  clientModel.setSuspended client_id, false, (err, res) ->
    next err, res if next? 

module.exports.suspend = (client_id, next) =>
  clientModel.setSuspended client_id, true, (err, res) ->
    next err, res if next? 
