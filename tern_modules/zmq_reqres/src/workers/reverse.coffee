Responder = require "../responder"

# System worker for connectivity testing.
#   Reverses the given string.
class Reverse
  run: (data, next) ->
    next null, data.split("").reverse().join("")

module.exports = Reverse