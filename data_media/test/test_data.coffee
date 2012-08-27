fs = require 'fs'
path = require 'path'

getTestUser = do ->
  filePath = path.resolve __dirname, '../../auth/test_user.json'
  userObj = JSON.parse fs.readFileSync filePath

  exports.user_id         = userObj.user_id
  exports.access_token    = userObj.access_token