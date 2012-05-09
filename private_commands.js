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

Commands.prototype.del = function(from, tokens, cb) {
    if (!this.users.get(from)) return;
    var first = _(tokens).head()
    if (first && /^\d+$/.test(first)) {
        var number = Number(first);
        if (this.users.deleteMsg(from, number - 1)) {
            cb('message number ' + number + ' has been deleted');
        } else cb('there is no message number ' + number);
    } else cb('delete requires a message number to delete');
}

Commands.prototype.phone = function(from, tokens, cb) {
    if (!this.users.get(from)) return;
    var first = _(tokens).head();
    if (first && /^\d+$/.test(first)) {
        this.users.setPhoneNumber(from, first);
        cb('your phone number has been recorded as ' + first);
    } else if (first && first === 'clear') {
        this.users.clearPhoneNumber(from);
        cb('your phone number has been cleared');
    } else {
        cb('number <actual number only digits> to set your number. number clear to clear your number');
    }
}

Commands.prototype.email = function(from, tokens, cb) {
    if (!this.users.get(from)) return;
    var first = _(tokens).head();
    if (first && /^[^@]+@[^@]+$/.test(first)) {
        this.users.setEmailAddress(from, first);
        cb('your email address has been recorded as ' + first);
    } else if (first && first === 'clear') {
        this.users.clearEmailAddress(from);
        cb('your email address has been cleared');
    } else {
        cb('email <email address> to set your email address. email clear to clear your it');
    }
}