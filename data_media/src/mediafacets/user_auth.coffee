Log        = require('tern.logger')
Token      = require '../agents/token_agent'
Err        = require './media_error'

userAuth = (req, res, next) ->
  authorization = req.headers.authorization
  return Err.sendError res, Err.CODES.AUTHORIZATION_REQUIRED unless authorization?

  [authMethod, accessToken] = authorization.match /[a-z0-9\-_]+/gi
  return Err.sendError res, Err.CODES.UNSUPPORTED_AUTHORIZATION_METHOD, authMethod unless authMethod is 'Bearer'
  return Err.sendError res, Err.CODES.CREDENTIAL_REQUIRED, authMethod unless accessToken?

  Token.getInfo accessToken, (err, user) ->
    if err?
      if err.name? and err.name is 'ResourceDoesNotExistException'        
        Err.sendError res, Err.CODES.INVALID_ACCESS_TOKEN
      else
        res.send 500
    else
      req._tern = {} unless req._tern?
      
      req._tern.user_id        = user.user_id
      req._tern.user_data_zone = user.data_zone
      req._tern.scope          = user.scope

      media_id = req.params.media_id
      return Err.sendError res, Err.CODES.MEDIA_ID_REQUIRED unless media_id?

      if media_id.split(':')[0] isnt req._tern.user_id
        return Err.sendError res, Err.CODES.UNMATCHED_MEDIA_ID, media_id

      req._tern.media_id = media_id

      next()

module.exports = userAuth