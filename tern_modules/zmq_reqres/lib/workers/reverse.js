// Generated by CoffeeScript 1.3.3
var Responder, Reverse;

Responder = require("../responder");

Reverse = (function() {

  function Reverse() {}

  Reverse.prototype.run = function(data, next) {
    return next(null, data.split("").reverse().join(""));
  };

  return Reverse;

})();

module.exports = Reverse;