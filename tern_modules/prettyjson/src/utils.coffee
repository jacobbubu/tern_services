###
# Creates a string with the same length as `numSpaces` parameter
###
exports.indent = (numSpaces) ->
  new Array(numSpaces + 1).join(' ')

###
# Gets the string length of the longer index in a hash
###
exports.getMaxIndexLength = (input) ->
  maxWidth = 0

  for k of input
    if k.length > maxWidth
      maxWidth = k.length
  maxWidth