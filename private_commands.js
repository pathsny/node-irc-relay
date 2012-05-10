var _ = require('underscore');
var gtalk = require('./gtalk').gtalk;

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
    cb('email <emailaddress> : sets an alert email address. email clear : clears the alert email address');
    cb('gtalk <gtalkid> : sets a gtalk id. gtalk clear : clears the gtalk id')
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

contact_points = {
    phone: {
        property: "PhoneNumber",
        regex: /^\d+$/,
        help: 'number <actual number only digits> to set your number. number clear it'
    },
    email: {
        property: "EmailAddress",
        regex: /^[^@]+@[^@]+$/,
        help: 'email <email address> to set your email address. email clear to clear it'
    },
    gtalk: {
        property: "GtalkId",
        regex: /^[^@]+@[^@]+$/,
        help: 'gtalk <gtalkid> to set your gtalk id. gtalk clear to clear it',
        custom_fn: _(gtalk.addAccount).bind(gtalk)
    }
};

_(contact_points).each(function(params, command){
    Commands.prototype[command] = function(from, tokens, cb) {
        if (!this.users.get(from)) return;
        var first = _(tokens).head();
        if (first && params.regex.test(first)) {
            if (!params.custom_fn) {
                this.users['set' + params.property](from, first);
                cb('your ' + params.property + ' has been recorded as ' + first);
            }
            else params.custom_fn(from, first, cb);
        } else if (first && first === 'clear') {
            this.users['clear' + params.property](from);
            cb('your ' + params.property + ' has been cleared');
        } else {
            cb(params.help);
        }
    }
});
