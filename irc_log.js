var fs = require('fs');
var _ = require('underscore');
require('./utils');


var Logger = exports.Logger = function(channel) {
    if (!(this instanceof Logger)) return new Logger(channel);
    this.channel = channel;
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
    }).value();
    var self = this;
    this._msgs = msgPartition[1];
    ws.write(data, function() {
        self.flushing = false;
        if (self._msgs.length) process.nextTick(_.bind(self._maybeFlush, self));
    });
}

Logger.prototype.listeners = function(){
    var self = this;
    return [
    {
        type: 'join',
        listener: function(channel, nick) {
            self.log(nick + " has joined the channel");
        }
    },
    {
        type: 'part',
        listener: function(channel, nick, reason) {
            var msg = nick + " has left the channel";
            if (reason) msg += " (" + reason + ")";
            self.log(msg);
        }
    },
    {
        type: 'kick',
        listener: function(channel, nick, by, reason) {
            var msg = nick + " has been kicked by " + by;
            if (reason) msg += " (" + reason + ")";
            self.log(msg);
        }
    },
    {
        type: 'quit',
        listener: function(nick, message, channels) {
            self.log(nick + " quit the channel (" + message + ")");
        }
    },
    {
        type: 'nick',
        listener: function(oldnick, newnick) {
            self.log(oldnick + " is now known as " + newnick);
        }
    },
    {
        type: 'message',
        listener: function(from, to, message) {
            if (self.channel === to) {
                self.log(_.displayChatMsg(from, message));
            }
        }
    },
    {
        type: 'notice',
        listener: function(from, to, message) {
            if (self.channel === to) {
                self.log("---<" + from + ">" + " " + message);
            }
        }
    },
    {
        type: 'topic',
        listener: function(channel, topic, nick) {
            self.log(nick + " changed the channel topic to " + topic);
        }
    },
    {
        type: 'raw',
        listener: function(message) {
            if (message.command === "TOPIC") {
                self.log(message.nick + " changed the channel topic to " + message.args[1]);
            }
            
            if (message.command === "MODE" && self.channel === message.args[0]) {
                var modes = message.args[1].split('');
                var adding = modes.shift() === "+";
                var other_params = message.args.slice(2);
                var user_modes = {
                    'v': 'voiced user',
                    'h': 'half operator',
                    'o': 'operator',
                    'a': 'administrator',
                    'q': 'founder'
                };
                var channel_modes = {
                    'n': ["permit outside messages", "prohibit outside messages"],
                    't': _(["require", "not require"]).map(function(p) {
                        return p + " operator status to change the topic";
                    }),
                    'm': ["moderated", "not moderated"],
                    'i': ["invite only", "not require invitation"],
                    "p": ["private", "public"],
                    "s": ["secret", "no longer remain a secret"]
                }
                
                _(modes).each(function(mode){
                    if (_(['+', '-']).include(mode)) {
                        adding = mode === "+";
                        return;
                    }
                    if (_(user_modes).chain().keys().include(mode).value())
                        self.log(other_params.shift() + " has been " + (adding ? "promoted to " : "demoted from ") + user_modes[mode] + " by " + message.nick);
                    else if (mode === 'b') 
                        self.log(message.nick + (adding ? " set a ban on " : " removed the ban on ") + other_params.shift()) 
                    else if (mode === 'k') 
                            self.log(message.nick + " changed the room to " + (adding ? "require a key of " + other_params.shift() : "not require a key"));
                    else if (mode === 'l') 
                            self.log(message.nick + " changed the room to " + (adding ? "limit the number of users to " +  other_params.shift() : "remove the limit on room members"))
                    else if (_(channel_modes).chain().keys().include(mode).value())
                            self.log(message.nick + " changed the room to " + (adding ? channel_modes[mode][0] : channel_modes[mode][1]));
                    else self.log(message.nick + " changed the mode to " + (adding ? "+" : "-") + mode)
                })
            }
        }
    }
            ];
}
