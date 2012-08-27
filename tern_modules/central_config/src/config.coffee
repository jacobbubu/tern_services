EventEmitter = require('events').EventEmitter

class Config extends EventEmitter
  constructor: (@path) ->

module.exports = Config

	