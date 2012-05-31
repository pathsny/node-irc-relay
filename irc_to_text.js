var _ = require('underscore');
require('./utils');
var util = require('util'),
EventEmitter = require('events').EventEmitter;

var IrcToText = exports.IrcToText = function(channel) {
    if (!(this instanceof IrcToText)) return new IrcToText(channel);
    this.channel = channel;
}
util.inherits(IrcToText, EventEmitter);

IrcToText.prototype.listeners = function(){
    var self = this;
    var emit = _(this.emit).bind(this, 'text');
    return [
    {
        type: 'join',
        listener: function(channel, nick) {
            emit(nick + " has joined the channel");
        }
    },
    {
        type: 'part',
        listener: function(channel, nick, reason) {
            var msg = nick + " has left the channel";
            if (reason) msg += " (" + reason + ")";
            emit(msg);
        }
    },
    {
        type: 'kick',
        listener: function(channel, nick, by, reason) {
            var msg = nick + " has been kicked by " + by;
            if (reason) msg += " (" + reason + ")";
            emit(msg);
        }
    },
    {
        type: 'quit',
        listener: function(nick, message, channels) {
            emit(nick + " quit the channel (" + message + ")");
        }
    },
    {
        type: 'nick',
        listener: function(oldnick, newnick) {
            emit(oldnick + " is now known as " + newnick);
        }
    },
    {
        type: 'message',
        listener: function(from, to, message) {
            if (self.channel === to) {
                emit(_.displayChatMsg(from, message));
            }
        }
    },
    {
        type: 'notice',
        listener: function(from, to, message) {
            if (self.channel === to) {
                emit("---<" + from + ">" + " " + message);
            }
        }
    },
    {
        type: 'topic',
        listener: function(channel, topic, nick) {
            emit(nick + " changed the channel topic to " + topic);
        }
    },
    {
        type: 'raw',
        listener: function(message) {
            if (message.command === "TOPIC") {
                emit(message.nick + " changed the channel topic to " + message.args[1]);
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
                        emit(other_params.shift() + " has been " + (adding ? "promoted to " : "demoted from ") + user_modes[mode] + " by " + message.nick);
                    else if (mode === 'b') 
                        emit(message.nick + (adding ? " set a ban on " : " removed the ban on ") + other_params.shift()) 
                    else if (mode === 'k') 
                            emit(message.nick + " changed the room to " + (adding ? "require a key of " + other_params.shift() : "not require a key"));
                    else if (mode === 'l') 
                            emit(message.nick + " changed the room to " + (adding ? "limit the number of users to " +  other_params.shift() : "remove the limit on room members"))
                    else if (_(channel_modes).chain().keys().include(mode).value())
                            emit(message.nick + " changed the room to " + (adding ? channel_modes[mode][0] : channel_modes[mode][1]));
                    else emit(message.nick + " changed the mode to " + (adding ? "+" : "-") + mode)
                })
            }
        }
    }
            ];
}
