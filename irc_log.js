var fs = require('fs');
var _ = require('underscore');
require('./utils');


var Logger = exports.Logger = function(textEmittor) {
    if (!(this instanceof Logger)) return new Logger(textEmittor);
    textEmittor.on('text', _(this.log).bind(this));
    this._msgs = [];
    this._flushing = false;
}

Logger.prototype._writestream = function(gmtDate) {
    if (this._gmtDate && this._gmtDate === gmtDate) return this._ws;
    if (this._ws) this._ws.end();
    this._gmtDate = gmtDate;
    this._ws = fs.createWriteStream('./data/irclogs/' + gmtDate + '.log',{
      encoding: 'utf-8',
      flags: 'a'
    });
    return this._ws;
}

Logger.prototype.log = function(msg) {
    this._msgs.push([_.now(), msg]);
    this._maybeFlush();
};

Logger.prototype._maybeFlush = function() {
    if (this.flushing) return;
    this.flushing = true;
    var date = _(this._msgs[0][0]).gmtDate();
    var ws = this._writestream(date);
    var msgPartition = _(this._msgs).partitionAt(function(msg){
        return _(msg[0]).gmtDate() === date;
    });
    var data = _(msgPartition).chain().first().map(function(msg){
        return JSON.stringify([msg[0].date.getTime(), msg[1]]) + '\n';
    }).value().join('');
    var self = this;
    this._msgs = msgPartition[1];
    ws.write(data, function() {
        self.flushing = false;
        if (self._msgs.length) process.nextTick(_.bind(self._maybeFlush, self));
    });
}

