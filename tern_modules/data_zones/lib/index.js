// Generated by CoffeeScript 1.3.3
var BrokersHelper, configObject, currentDataZone, currentObj, dataZones, init;

BrokersHelper = require('tern.central_config').BrokersHelper;

configObject = null;

dataZones = null;

currentObj = null;

currentDataZone = '';

init = function() {
  currentObj = BrokersHelper.getConfig('dataZone');
  if (currentObj != null) {
    currentDataZone = currentObj.value;
    currentObj.on('changed', function(oldValue, newValue) {
      console.log("current dataZone config changed from '" + oldValue + "' to '" + newValue + "'");
      return currentDataZone = newValue;
    });
  } else {
    throw new Error("Can not get 'dataZone' from config brokers");
  }
  configObject = BrokersHelper.getConfig('dataZones');
  if (configObject != null) {
    dataZones = configObject.value;
    return configObject.on('changed', function(oldValue, newValue) {
      console.log('dataZones config changed');
      return dataZones = newValue;
    });
  } else {
    throw new Error("Can not get 'dataZones' from config brokers");
  }
};

module.exports.currentDataZone = function() {
  if (currentObj == null) {
    init();
  }
  return currentDataZone;
};

module.exports.get = function(dataZone) {
  if (configObject == null) {
    init();
  }
  return dataZones[dataZone];
};

module.exports.all = function() {
  if (configObject == null) {
    init();
  }
  return dataZones;
};

module.exports.getWebSocketBind = function(dataZone) {
  if (configObject == null) {
    init();
  }
  return dataZones[dataZone].websocket.bind;
};

module.exports.getWebSocketConnect = function(dataZone) {
  if (configObject == null) {
    init();
  }
  return dataZones[dataZone].websocket.connect;
};

module.exports.getMediaBind = function(dataZone) {
  if (configObject == null) {
    init();
  }
  return dataZones[dataZone].media.bind;
};

module.exports.getMediaConnect = function(dataZone) {
  if (configObject == null) {
    init();
  }
  return dataZones[dataZone].media.connect;
};

module.exports.getDataQueuesConfig = function(dataZone) {
  if (configObject == null) {
    init();
  }
  return dataZones[dataZone].dataQueuesToOtherZones;
};

module.exports.getMediaQueuesConfig = function(dataZone) {
  if (configObject == null) {
    init();
  }
  return dataZones[dataZone].mediaQueuesToOtherZones;
};
