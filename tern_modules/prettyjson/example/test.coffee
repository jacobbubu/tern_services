prettyjson = require '../lib/index'

obj = 
  k3: 1234
  k2:
    k21: 'v21'
    k22: 'v22'
  k1: true

console.log prettyjson.render obj