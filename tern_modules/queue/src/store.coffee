redis = require "redis"

module.exports = class RedisStore
  constructor: ( @options = {} ) ->
    @client = redis.createClient @options.port? or 6379
      , @options.host? or 'localhost'
      , { enable_offline_queue: false }

    @options.bucket ?= 'queueServer-store'

    @client.select @options.dbid? or 0, (err) ->
      if err?
        throw new Error(message)
      return

  write: (key, data, next) ->
    @client.hset @options.bucket, key, data, next

  read: (key, next) ->
    @client.hget @options.bucket, key, next

  delete: (key, next) ->
    @client.hdel @options.bucket, key, next

  keys: (next) ->
    @client.hkeys @options.bucket, next