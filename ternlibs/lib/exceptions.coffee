
createError = (message, name) ->
  err = new Error(message)
  err.name = name
  return err

###
# ArgumentException
###
exports.ArgumentException = (message) ->
  return createError message, "ArgumentException"

exports.ArgumentNullException = (message) ->
  return createError message, "ArgumentNullException"

exports.ArgumentLengthException = (message) ->
  return createError message, "ArgumentLengthException"

exports.ArgumentInRangeException = (message) ->
  return createError message, "ArgumentInRangeException"

exports.ArgumentInRangeException = (message) ->
  return createError message, "ArgumentInRangeException"

exports.ArgumentUnsupportedException = (message) ->
  return createError message, "ArgumentUnsupportedException"

###
# Resource
###
exports.ResourceExistsException = (message) ->
  return createError message, "ResourceExistsException"

exports.ResourceDoesNotExistException = (message) ->
  return createError message, "ResourceDoesNotExistException"

###
# Timeout
###
exports.TimeoutException = (message) ->
  return createError message, "TimeoutException"

