Utils = require 'tern.utils'

exports.isEmpty = (value) ->
  return true if not value?
    
  type = typeof value
  switch type
    when 'string'
      return value.trim().length is 0
    else
      return false

exports.isLengthIn = (value, min, max) ->
  [min, max] = [max, min] if min > max
  
  type = typeof value
  switch type
    when 'string'
      len = value.trim().length
      return min <= len <= max        
    else
      throw new TypeError "Unsupported param type '#{type}'."

exports.isInRangeOf = (value, min, max) ->
  [min, max] = [max, min] if min > max
  
  type = typeof value
  switch type
    when 'number'      
      return min <= value <= max        
    else
      throw new TypeError "Unsupported param type '#{type}'."

exports.isMatched = (value, pattern) ->
  if (typeof value) isnt 'string'
    throw new TypeError "Unsupported param type '#{typeof value}'."

  unless pattern instanceof RegExp
    throw new TypeError "Need RegExp for pattern."

  return pattern.test value

exports.keysCount = (value) ->
  throw new TypeError("'value' required.") if not value?
    
  type = typeof value
  switch type
    when 'object'
      return Object.keys(value).length
    else
      throw new TypeError "Unsupported param type '#{type}'."

###
  rules:
    'REQUIRED': true
    'LENGTH':
      min: 1
      max: 24
    'RANGE':
      min: -180
      max: 180
    'PATTERN': /^\d+$/
    'UNSUPPORTED' : ['add', 'update', 'delete']
    'NUMBER':  true          #need number
    'INTEGER': true          #need number
    'STRING':  true          #need string
    'STRING_INTEGER':  true  #signed integer, expressed in string
    'BOOLEAN': true          #need boolean
    'ISODATE': true          #need string in ISODatetime format
    'NAME_INTEGER': true     #a string in the form of 'name:signed integer'
###
exports.checkRules = (value, rules) ->
  result = []

  for name, rule of rules
    unless value?
      result.push('REQUIRED') if exports.isEmpty(value)
    else    
      switch name
        when 'REQUIRED'
          result.push('REQUIRED') if exports.isEmpty(value)
        when 'STRING'
          result.push('STRING') if Utils.type(value) isnt 'string'
        when 'NUMBER'
          result.push('NUMBER') if Utils.type(value) isnt 'number'
        when 'OBJECT'
          result.push('OBJECT') if Utils.type(value) isnt 'object'          
        when 'INTEGER'
          if Utils.type(value) isnt 'number'
            result.push('INTEGER')
          else
            result.push('INTEGER') if Math.floor(value) isnt value
        when 'BOOLEAN'
          result.push('BOOLEAN') if Utils.type(value) isnt 'boolean'
        when 'ARRAY'
          result.push('ARRAY') if Utils.type(value) isnt 'array'          
        when 'LENGTH'
          if Utils.type(value) isnt 'string'
            result.push('STRING')
          else
            result.push("LENGTH:#{rule.min}:#{rule.max}") unless exports.isLengthIn(value, rule.min, rule.max)
        when 'RANGE'
          if Utils.type(value) isnt 'number'
            unless rules.INTEGER?
              result.push('NUMBER')
          else
            result.push("RANGE:#{rule.min}:#{rule.max}") unless exports.isInRangeOf(value, rule.min, rule.max)
        when 'UNSUPPORTED'
          result.push 'UNSUPPORTED' unless value in rule
        when 'UNSUPPORTED/i'
          if Utils.type(value) is 'string'
            value = value.toLowerCase()

          result.push 'UNSUPPORTED' unless value in rule
        when 'PATTERN'
          if Utils.type(value) isnt 'string'
            result.push('STRING')
          else      
            result.push 'PATTERN' unless exports.isMatched(value, rule)
        when 'STRING_INTEGER'
          if Utils.type(value) isnt 'string'
            result.push('STRING')
          else      
            result.push 'STRING_INTEGER' unless exports.isMatched(value, /^[+-]?\d{1,18}$/)
        when 'STRING_INTEGER_WITH_INF'
          if Utils.type(value) isnt 'string'
            result.push('STRING')
          else
            unless value in ['+inf', '-inf']
              result.push 'STRING_INTEGER' unless exports.isMatched(value, /^[+-]?\d{1,18}$/)            
        when 'ISODATE'
          if Utils.type(value) isnt 'string'
            result.push('ISODATE')
          else      
            result.push 'ISODATE' unless exports.isMatched(value, /^(\d{4})\D?(0[1-9]|1[0-2])\D?([12]\d|0[1-9]|3[01])([T]([01]\d|2[0-3])[:]([0-5]\d)[:]([0-5]\d)?[\.]?(\d{3})?([zZ])?)$/)
        when 'NAME_INTEGER'
          if Utils.type(value) isnt 'string'
            result.push('STRING')
          else      
            result.push 'NAME_INTEGER' unless exports.isMatched(value, /^([^\s]{1,24}):[+-]?(\d{1,18})$/)
        when 'TAG_KEY'
          if Utils.type(value) isnt 'string'
            result.push('TAG_KEY')
          else
            result.push 'TAG_KEY' unless (Utils.splitTagKey value).length > 1
          
  obj = {}
  obj[v] = true for v in result

  result = Object.keys(obj)

exports.checkRulesWithError = (argName, value, rules, error) ->
  res = exports.checkRules value, rules
  if res.length > 0
    error = {} unless error?
    error[argName] = res
    
  return error

exports.collectErrors = (argName, paramObj, rules, error) ->

  subObjs = argName.split '.'
  switch subObjs.length 
    when 1
      value = paramObj[subObjs[0]]
    when 2
      value = paramObj[subObjs[0]][subObjs[1]]
    when 3
      value = paramObj[subObjs[0]][subObjs[1]][subObjs[2]]
    when 4
      value = paramObj[subObjs[0]][subObjs[1]][subObjs[2]][subObjs[3]]
    else
      throw new Error("Too many levels in #{argName}.")
  
  res = exports.checkRules value, rules[argName]
  if res.length > 0
    error = {} unless error?
    error[argName] = res
    
  return error





