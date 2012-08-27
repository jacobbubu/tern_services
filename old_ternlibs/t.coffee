HTTP = require 'http'

STATUS_CODES = {}

buildStatusCodes = do ->
  httpStatusCodes = HTTP.STATUS_CODES
  for k, v of httpStatusCodes
    v = v.replace /\s/g, ''
    console.log v
    STATUS_CODES[v] = Number(k)

console.dir STATUS_CODES