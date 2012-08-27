// Generated by CoffeeScript 1.3.3
var Checker, DB, DefaultWinSize, Err, FolderNames, Log, MaxWaitTime, MaxWinSize, MinWaitTime, MinWinSize, ParamRules, Timers, Utils, WSMessageHelper, coreClass, subscriptionModel, _SubscriptionModel,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  _this = this;

Log = require('tern.logger');

Err = require('tern.exceptions');

Checker = require('tern.param_checker');

DB = require('tern.database');

Utils = require('tern.utils');

Timers = require('timers');

WSMessageHelper = require('tern.ws_message_helper');

FolderNames = ['memos', 'tags'];

DefaultWinSize = 200;

MaxWinSize = 500;

MinWinSize = 1;

MinWaitTime = 100;

MaxWaitTime = 1500;

ParamRules = {
  'win_size': {
    'RANGE': {
      min: MinWinSize,
      max: MaxWinSize
    }
  },
  'name': {
    'UNSUPPORTED/i': FolderNames
  },
  'min_ts': {
    'STRING_INTEGER_WITH_INF': true
  },
  'max_ts': {
    'STRING_INTEGER_WITH_INF': true
  }
};

coreClass = (function() {
  var _instance;

  function coreClass() {}

  _instance = void 0;

  coreClass.get = function() {
    return _instance != null ? _instance : _instance = new _SubscriptionModel;
  };

  return coreClass;

})();

_SubscriptionModel = (function() {

  function _SubscriptionModel() {
    this.get = __bind(this.get, this);

    this.unsubscribe = __bind(this.unsubscribe, this);

    this.subscribe = __bind(this.subscribe, this);

    this.changeLogChecking = __bind(this.changeLogChecking, this);

    this.subsChecking = __bind(this.subsChecking, this);
    this.db = DB.getDB('userDataDB');
  }

  _SubscriptionModel.prototype.subsChecking = function(connection, subs) {
    var calcWaitTime, waitTime,
      _this = this;
    calcWaitTime = function() {
      var totalConns;
      totalConns = connection._tern.ws_server.connections.length;
      return Math.min(MinWaitTime + totalConns, MaxWaitTime);
    };
    if (Object.keys(subs.folders).length !== 0) {
      waitTime = calcWaitTime();
    } else {
      waitTime = MaxWaitTime;
    }
    if (connection._tern.timeoutId != null) {
      Timers.clearTimeout(connection._tern.timeoutId);
      connection._tern.timeoutId = null;
    }
    return this.changeLogChecking(connection, subs, function(err, res) {
      if (err != null) {
        Log.error(err.toString());
      }
      connection._tern.timeoutId = Timers.setTimeout(_this.subsChecking, waitTime, connection, subs);
    });
  };

  _SubscriptionModel.prototype.changeLogChecking = function(connection, subs, next) {
    var device_id, script, user_id,
      _this = this;
    user_id = connection._tern.user_id;
    device_id = connection._tern.device_id;
    script = "local userId    = ARGV[1]\nlocal folders   = cjson.decode(ARGV[2])\nlocal totalSize = ARGV[3]\nlocal deviceId  = ARGV[4]\n\nlocal changelogBase = 'users/'..userId..'/changelog/'\nlocal changelogKey\n\nlocal result = {}\nlocal fRes, dRes\nlocal count = 0\n\nlocal function array_concat(arr1, arr2)\n  for _, v in ipairs(arr2) do\n    arr1[#arr1+1] = v\n  end\n  return arr1\nend\n\nlocal devices = redis.call('SMEMBERS', 'users/'..userId..'/devices')\n\nfor name, f in pairs(folders) do\n  fRes = {}\n  for _, dev in pairs(devices) do\n    if dev ~= deviceId then\n      changelogKey = changelogBase..name..'/'..dev\n      dRes = redis.call('ZRANGEBYSCORE', changelogKey, f.min_ts, f.max_ts, 'LIMIT', 0, f.win_size)\n      fRes = array_concat(fRes, dRes)\n    end\n  end\n  if next(fRes) == nil then\n    fRes = nil\n  end\n  result[name] = fRes\nend\n\nreturn cjson.encode(result)  ";
    return this.db.run_script(script, 0, user_id, JSON.stringify(subs.folders), device_id, function(err, res) {
      var currentCount, f, finalResult, folderName, k, logs, originalLength, pushRequest, result, shouldDelete, totalCount, win_size, _ref, _ref1;
      if (err != null) {
        return next(err);
      }
      try {
        finalResult = {
          total_count: 0,
          folders: {}
        };
        result = JSON.parse(res);
        for (folderName in result) {
          logs = result[folderName];
          if (Object.keys(logs).length > 0) {
            logs.sort(function(log1, log2) {
              if (log1.ts === log2.ts) {
                return 0;
              }
              if (log1.ts < log2.ts) {
                return -1;
              } else {
                return 1;
              }
            });
            win_size = (_ref = subs.folders[folderName]) != null ? _ref.win_size : void 0;
            if (win_size != null) {
              originalLength = logs.length;
              logs.splice(Math.min(logs.length, win_size));
              if (logs.length > 0) {
                finalResult.folders[folderName] = {
                  changelog: logs,
                  has_more: originalLength > logs.length
                };
              }
            }
          }
        }
        if (Object.keys(finalResult.folders).length === 0) {
          return next(null, finalResult);
        }
        totalCount = subs.win_size;
        currentCount = 0;
        shouldDelete = false;
        _ref1 = finalResult.folders;
        for (k in _ref1) {
          f = _ref1[k];
          if (shouldDelete) {
            delete finalResult.folders[k];
          } else {
            if (currentCount + f.changelog.length >= totalCount) {
              originalLength = f.changelog.length;
              f.changelog.splice(totalCount - currentCount);
              f.has_more = originalLength > f.changelog.length;
              shouldDelete = true;
              currentCount = totalCount - currentCount;
            } else {
              currentCount = currentCount + f.changelog.length;
            }
          }
        }
        finalResult.total_count = currentCount;
        pushRequest = {
          request: {
            method: 'data.subscription.push',
            req_ts: Utils.getTimestamp(),
            data: finalResult
          }
        };
        return WSMessageHelper.send(connection, JSON.stringify(pushRequest), function(err) {
          var _ref2;
          if (err != null) {
            return next(err);
          }
          _ref2 = finalResult.folders;
          for (k in _ref2) {
            f = _ref2[k];
            if (subs.folders[k] != null) {
              delete subs.folders[k];
            }
          }
          return next(null, finalResult);
        });
      } catch (e) {
        return next(e);
      }
    });
  };

  _SubscriptionModel.prototype.subscribe = function(request, connection, next) {
    var data, error, folder, folderName, res, subs, _base, _ref, _ref1, _ref2;
    data = request.data;
    error = null;
    error = Checker.checkRulesWithError("data", data, {
      'OBJECT': true
    }, error);
    if (error == null) {
      if (data.win_size != null) {
        error = Checker.collectErrors('win_size', data, ParamRules, error);
      }
      if (data.folders != null) {
        _ref = data.folders;
        for (folderName in _ref) {
          folder = _ref[folderName];
          error = Checker.checkRulesWithError("folders[" + folderName + "]", folderName, ParamRules.name, error);
          if (folder.win_size != null) {
            error = Checker.checkRulesWithError("folders[" + folderName + "].win_size", folder.win_size, ParamRules.win_size, error);
          }
          error = Checker.checkRulesWithError("folders[" + folderName + "].min_ts", folder.min_ts, ParamRules.min_ts, error);
          error = Checker.checkRulesWithError("folders[" + folderName + "].max_ts", folder.max_ts, ParamRules.max_ts, error);
        }
      }
    }
    if (error != null) {
      res = {
        status: -1,
        error: error
      };
      return next(null, res);
    }
    subs = connection._tern.subscritions;
    if (subs == null) {
      subs = {
        win_size: DefaultWinSize,
        folders: {}
      };
    }
    if (data.win_size != null) {
      subs.win_size = data.win_size;
    }
    _ref1 = data.folders;
    for (folderName in _ref1) {
      folder = _ref1[folderName];
      if (subs.folders[folderName] == null) {
        subs.folders[folderName] = {};
      }
      if (folder.win_size != null) {
        subs.folders[folderName].win_size = folder.win_size;
      } else {
        if ((_ref2 = (_base = subs.folders[folderName]).win_size) == null) {
          _base.win_size = DefaultWinSize;
        }
      }
      subs.folders[folderName].min_ts = folder.min_ts;
      subs.folders[folderName].max_ts = folder.max_ts;
    }
    connection._tern.subscritions = subs;
    res = {
      status: 0
    };
    Timers.setTimeout(this.subsChecking, 0, connection, subs);
    return next(null, res);
  };

  _SubscriptionModel.prototype.unsubscribe = function(request, connection, next) {
    var data, error, folderName, res, subs, _i, _j, _len, _len1;
    data = request.data;
    error = null;
    error = Checker.checkRulesWithError("data", data, {
      'ARRAY': true
    }, error);
    for (_i = 0, _len = data.length; _i < _len; _i++) {
      folderName = data[_i];
      error = Checker.checkRulesWithError("" + folderName, folderName, ParamRules.name, error);
    }
    if (error != null) {
      res = {
        status: -1,
        error: error
      };
      return next(null, res);
    }
    subs = connection._tern.subscritions;
    if (subs != null) {
      for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
        folderName = data[_j];
        if (subs.folders[folderName] != null) {
          delete subs.folders[folderName];
        }
      }
      connection._tern.subscritions = subs;
    }
    res = {
      status: 0
    };
    return next(null, res);
  };

  _SubscriptionModel.prototype.get = function(connection, next) {
    var res;
    res = {
      status: 0,
      result: connection._tern.subscritions
    };
    return next(null, res);
  };

  return _SubscriptionModel;

})();

/*
# Module Exports
*/


subscriptionModel = coreClass.get();

module.exports.subscribe = function(request, connection, next) {
  return subscriptionModel.subscribe(request, connection, function(err, res) {
    if (next != null) {
      return next(err, res);
    }
  });
};

module.exports.unsubscribe = function(request, connection, next) {
  return subscriptionModel.unsubscribe(request, connection, function(err, res) {
    if (next != null) {
      return next(err, res);
    }
  });
};

module.exports.get = function(connection, next) {
  return subscriptionModel.get(connection, function(err, res) {
    if (next != null) {
      return next(err, res);
    }
  });
};