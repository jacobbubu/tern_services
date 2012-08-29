FS   = require 'fs'
Path = require 'path'

readLogoFromFile = (fileaName, version) ->
  version = version ? ''
  logo = FS.readFileSync Path.resolve(__dirname, fileaName), 'utf8'
  logo.replace '$version$', version

module.exports = (version) -> 
  readLogoFromFile '../logos/tern.txt', version

module.exports.Auth = (version) -> 
  readLogoFromFile '../logos/auth.txt', version

module.exports.WebSocket = (version) -> 
  readLogoFromFile '../logos/web_socket.txt', version

module.exports.Media = (version) -> 
  readLogoFromFile '../logos/media.txt', version

module.exports.Queue = (version) -> 
  readLogoFromFile '../logos/queue.txt', version

module.exports.MediaQueues = (version) -> 
  readLogoFromFile '../logos/media_queues.txt', version  

module.exports.DataQueues = (version) -> 
  readLogoFromFile '../logos/data_queues.txt', version  

module.exports.GlobalConfig = (version) -> 
  readLogoFromFile '../logos/global_config.txt', version

module.exports.ZoneConfig = (version) -> 
  readLogoFromFile '../logos/zone_config.txt', version
                         