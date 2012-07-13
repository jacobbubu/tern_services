fs = require 'fs'

getTestUser = do ->
  userObj = JSON.parse fs.readFileSync('../auth/test_user.json')
  exports.user_id         = userObj.user_id
  exports.access_token    = userObj.access_token