LRU     = require "expiring-lru-cache"

# Performance Counter Prefix
#   EXAMPLE:
#     "rongmbp.12764.cache"
#PerfPrefix = [require("os").hostname(), process.pid, "cache"].join "."
PerfPrefix = ""

class Cache
  constructor: (@name, @options) ->
    throw new ArgumentNullException "'name' required." if not name?

    @innerLRU       = new LRU(options)
    @total_request  = 0
    @hit_request    = 0
    @perfKey        = [PerfPrefix, name].join "."

  set: ->
    return @innerLRU.set.apply(@innerLRU, arguments)

  get: ->
    @total_request++

    result = @innerLRU.get.apply(@innerLRU, arguments)
    @hit_request++ if result?

    if @total_request % 10 is 0
      hitRatio = @hit_request / @total_request * 100
      Perf.gauges @perfKey, hitRatio

    return result

  del: ->
    return @innerLRU.del.apply(@innerLRU, arguments)

module.exports = Cache
