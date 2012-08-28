// Generated by CoffeeScript 1.3.3
var FS, Path, readLogoFromFile;

FS = require('fs');

Path = require('path');

readLogoFromFile = function(fileaName, version) {
  var logo;
  version = version != null ? version : '';
  logo = FS.readFileSync(Path.resolve(__dirname, fileaName), 'utf8');
  return logo.replace('$version$', version);
};

module.exports = function(version) {
  return readLogoFromFile('../logos/tern.txt', version);
};

module.exports.Auth = function(version) {
  return readLogoFromFile('../logos/auth.txt', version);
};

module.exports.WebSocket = function(version) {
  return readLogoFromFile('../logos/web_socket.txt', version);
};

module.exports.Media = function(version) {
  return readLogoFromFile('../logos/media.txt', version);
};

module.exports.Queue = function(version) {
  return readLogoFromFile('../logos/queue.txt', version);
};

module.exports.GlobalConfig = function(version) {
  return readLogoFromFile('../logos/global_config.txt', version);
};

module.exports.ZoneConfig = function(version) {
  return readLogoFromFile('../logos/zone_config.txt', version);
};
