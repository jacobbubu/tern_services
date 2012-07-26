###
# Expose version using `pkginfo`
###
require('pkginfo')(module, 'version', 'author')

### 
# main.coffee
###

module.exports.consts             = require './consts/consts'
module.exports.logger             = require './lib/logger'
module.exports.config             = require './lib/config'
module.exports.utils              = require './lib/utils'
module.exports.perf_counter       = require './lib/perf_counter'
module.exports.i18n               = require './lib/i18n'
module.exports.exceptions         = require './lib/exceptions'
module.exports.database           = require './lib/database'
module.exports.cache              = require './lib/cache'
module.exports.param_checker      = require './lib/param_checker'
module.exports.counter            = require './lib/counter'
module.exports.zmq_sender         = require './lib/zmq_sender'
module.exports.zmq_responder      = require './lib/zmq_responder'
module.exports.zmq_status_codes   = require './lib/zmq_status_codes'
module.exports.lzf                = require './lib/lzf'
module.exports.default_ports      = require './lib/default_ports'
module.exports.ws_message_helper  = require './lib/ws_message_helper'
module.exports.spawn_server_test  = require './lib/spawn_server_test'
module.exports.test_log           = require './lib/test_log'
module.exports.media_type         = require './lib/media_type'
module.exports.sys_device_ids     = require './lib/sys_device_ids'
module.exports.tern_logo          = require './lib/tern_logo'
