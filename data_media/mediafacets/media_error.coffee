Util = require 'util'
Log  = require('ternlibs').logger

MEDIA_ERROR =
  CODES:
    AUTHORIZATION_REQUIRED                : -1001
    UNSUPPORTED_AUTHORIZATION_METHOD      : -1002
    CREDENTIAL_REQUIRED                   : -1003
    INVALID_ACCESS_TOKEN                  : -1004
    UNMATCHED_MEDIA_ID                    : -1005

    CONTENT_LENGTH_REQUIRED               : -2001
    CONTENT_LENGTH_IS_OOR                 : -2002

    CONTENT_RANGE_REQUIRED                : -2011
    CONTENT_RANGE_UNSUPPORTED_UNIT        : -2012
    CONTENT_RANGE_INVALID_INSTANCE_LENGTH : -2013    
    CONTENT_RANGE_INSTANCE_LENGTH_IS_OOR  : -2014

    CONTENT_TYPE_REQUIRED                 : -2021
    CONTENT_TYPE_UNSUPPORTED              : -2022
        
    INVALID_MEDIA_ID_FORMAT               : -2031
    MEDIA_ID_REQUIRED                     : -2032

    BAD_MD5                               : -2041
    UNMATCHED_MD5                         : -2042
    
    CONTENT_LENGTH_IS_GREATER_THAN_INSTANCE_LENGTH: -2051

  MESSAGES:
    "-1001": "Authorization required."
    "-1002": "Unsupported authorization method '(%s)'."
    "-1003": "Credential required."
    "-1004": "Invalid access token."
    "-1005": "This is not your media id '(%s)'."

    "-2001": "Content-Length required."
    "-2002": "Entity size should be in range of %s~%s Bytes"

    "-2011": "Content-Range required."
    "-2012": "Unsupported unit in Content-Range."
    "-2013": "Invalid instance length in Content-Range."
    "-2014": "Instance length in Content-Range is out of range of %s~%s Bytes."

    "-2021": "Content-Type required."
    "-2022": "Unsupported Media Type."

    "-2041": "Bad MD5."
    "-2042": "Unmatched MD5."
    "-2051": "Content-Length can not greater than instance length in Content-Range."

  HTTP_STATUS_CODES:
    "-1001": 401
    "-1002": 401
    "-1003": 401
    "-1004": 401
    "-1005": 403

    "-2001": 411
    "-2002": 413

    "-2011": 400
    "-2012": 400
    "-2013": 400
    "-2014": 400

    "-2021": 400
    "-2022": 415

    "-2031": 400
    "-2032": 400

    "-2041": 400
    "-2042": 400

    "-2051": 400


# res: An express response object
sendErrorResponse = (res, error_code, params...) ->
  try
    params.unshift MEDIA_ERROR.MESSAGES[error_code]
    message = Util.format.apply(module, params)
    
    errorObject = 
      status: error_code
      message: message

    res.send errorObject, MEDIA_ERROR.HTTP_STATUS_CODES[error_code]

  catch e
    res.send 500
    Log.error "Error sending response: ", e.toString()

module.exports.CODES = MEDIA_ERROR.CODES
module.exports.sendError = sendErrorResponse
