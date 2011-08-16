var _ = require('underscore');
require('./utils');

var Commands = exports.Commands = function(users, settings) {
    if (!(this instanceof Commands)) return new Commands(users, settings);
    this.users = users;
    this.settings = settings;
}

Commands.prototype.help = function(from, tokens, cb) {
    cb('token : gives you a token for the web history at www.got-rice.asia:8008');
    cb('list : lists all messages left for you');
    cb('del <x> : deletes the xth message');
}

Commands.prototype.token = function(from, tokens, cb) {
    var token = this.users.createToken(from);
    if (token) cb(token);
}

Commands.prototype.list = function(from, tokens, cb) {
    if (!this.users.get(from)) return;
    var msgs = this.users.getMsgs(from);
    if (msgs.length > 0) {
        _(msgs).chain().zipWithIndex().forEach(function(item){
            var msg = item[0]
            var reply = (item[1] + 1) + '. ' + msg.from + " said '" + msg.msg + "'";
            if (msg.time) {reply += " " + _.date(msg.time).fromNow()}
            cb(reply);
        });
    } else {
        cb("There are no messages for you");
    }
}