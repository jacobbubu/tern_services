Utils = require('ternlibs').utils

# Path: users/[user_id]/devices
# Type: set
module.exports.DevicesKey = (user_id) ->
  return Utils.pathJoin 'users', user_id, 'devices'

# Path: users/[user_id]/memos/[mid]
# Type: hash
module.exports.MemosKey = (user_id, mid) ->
  return Utils.pathJoin 'users', user_id, 'memos', mid

# Path: users/[user_id]/memos
# Type: NA
module.exports.MemosBase = (user_id) ->
  return Utils.pathJoin 'users', user_id, 'memos'

# Path: users/[user_id]/change_log/memos/[device_id]
# Type: zset
module.exports.MemosChangeLogKey = (user_id, device_id) ->
  return Utils.pathJoin 'users', user_id, 'changelog', 'memos', device_id

# Path: users/[user_id]/tidmid
# Type: set
module.exports.TidMidBaseKey = (user_id) ->
  return Utils.pathJoin 'users', user_id, 'tid_mid'

# Path: users/[user_id]/tidmid
# Type: set
module.exports.TagsKey = (user_id, tid) ->
  return Utils.pathJoin 'users', user_id, 'tags', tid

# Path: users/[user_id]/tags
# Type: NA
module.exports.TagsBase = (user_id) ->
  return Utils.pathJoin 'users', user_id, 'tags'

# Path: users/[user_id]/tagkey_to_tid
# Type: NA
module.exports.TagKeyMappingBase = (user_id) ->
  return Utils.pathJoin 'users', user_id, 'tagkey_to_tid'

# Path: users/[user_id]/changelog/tags/[device_id]
# Type: zset
module.exports.TagsChangeLogKey = (user_id, device_id) ->
  return Utils.pathJoin 'users', user_id, 'changelog', 'tags', device_id

