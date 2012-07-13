Log   = require('ternlibs').logger
Token = require '../models/token_mod'

userAuth = (req, res, next) ->
  authorization = req.headers.authorization
  return res.send("Authorization required.", 401) unless authorization?

  [authMethod, accessToken] = authorization.match /[a-z0-9\-_]+/gi
  return res.send("Unsupported authorization method '#{authMethod }'.", 401) unless authMethod is 'Bearer'
  return reject("Credential required.", 401) unless accessToken?

  Token.getInfo accessToken, (err, res) ->
    if err?
      if err.name? and err.name is 'ResourceDoesNotExistException'
        res.send 401
      else
        res.send 500
    else
      next()

module.exports = userAuth