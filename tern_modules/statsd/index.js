var socket      = require('dgram').createSocket('udp4')
  , mersenne    = require('mersenne')
  , mt          = new mersenne.MersenneTwister19937()
  , Log         = require("tern.logger");

StatsD = function (host, port) {
    this.host = host;
    this.port = port;
}

StatsD.prototype.timing = function (stat, time, sample_rate) {
    var self = this;
    var stats = {};

    stats[stat] = time+"|ms";
    self.send(stats, sample_rate);
};

StatsD.prototype.increment = function (stats, sample_rate) {
    var self = this;
    self.update_stats(stats, 1, sample_rate);
}

StatsD.prototype.decrement = function (stats, sample_rate) {
    var self = this;
    self.update_stats(stats, -1, sample_rate);
}

StatsD.prototype.update_stats = function (stats, delta, sampleRate) {
    var self = this;
    if (typeof(stats) === 'string') {
        stats = [stats];
    }
    if (!delta) {
        delta=1;
    }
    var data = {};
    for (var i = 0; i < stats.length; i++) {
        data[stats[i]] = delta + "|c";
    }
    self.send(data, sampleRate);
}

// Gauges- Added by Rong Shen
StatsD.prototype.gauges = function (stats, value) {
    var self = this;
    if (typeof(stats) === 'string') {
        stats = [stats];
    }
    var data = {};
    for (var i = 0; i < stats.length; i++) {
        data[stats[i]] = value + "|g";
    }
    self.send(data);
}

StatsD.prototype.send = function (data, sample_rate) {
    var self = this;
    var stat, send_data;

    if (!sample_rate) {
        sample_rate = 1;
    }

    var sampled_data = {};
    if(sample_rate < 1) {
        if (mt.genrand_real2(0,1) <= sample_rate) {
            for (stat in data) {
                value = data[stat];
                sampled_data[stat] = value + "|@" + sample_rate;
            }
        }
    }
    else {
        sampled_data = data;
    }
    for (stat in sampled_data) {
        send_data = stat + ":" + sampled_data[stat];
        send_data = new Buffer(send_data);
        socket.send(send_data, 0, send_data.length, self.port, self.host,
                    function (err, bytes) {
                        if (err) {
                            Log.error('statsd: ' + err.toString());
                        }
                    }
                   );
    }
};

module.exports = StatsD;
