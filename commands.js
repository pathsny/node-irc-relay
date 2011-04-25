var _ = require('./underscore');
require('./utils');

var Commands = exports.Commands = function(users) {
    if (!(this instanceof Commands)) return new Commands(users);
    this.users = users;
}
    
Commands.prototype.commands = function(from, token, cb) {
    cb("I know " + _(Commands.prototype).chain().keys().
    without("listeners").
    without("private").
    without("commands").
    map(function(command){
        return command + "!";
    }).
    sentence().value());
};

Commands.prototype.tell = function(from, tokens, cb) {
    var to = _(tokens).head();
    var msg = _(tokens).tail().join(' ');
    if (!(to && msg)) {
        cb("Message not understood");
    } else if(!this.users.get(to)) {
        cb(to + " is not known");
    } else {
        this.users.addTell(to, {from: from, msg: msg});
        cb(from + ": Message Noted");
    }
};

Commands.prototype.nick = function(from, tokens, cb) {
    var user = _(tokens).head();
    if (!user) {
        cb("it's nick! <username> ");
    } else {
        var aliases = this.users.aliasedNicks(user);
        if (!aliases) {
            cb(user + " is not known");
        } else {
            cb("known nicks of " + user + " are " + _(aliases).sentence());
        }
    }
};

Commands.prototype.link = function(from, tokens, cb) {
    var nick = _(tokens).head();
    var group = _(tokens).chain().tail().head().value();
    if (!(nick && group)) {
        cb("link <nick> <group>");
    } else {
        var result = this.users.link(nick, group);
        if (result) cb(nick + " has been linked with " + group);
            else cb('link only known UNLINKED nicks with other nicks');
    }
};

Commands.prototype.listeners = function(respond){
    var self = this;
    return [
    // convey messages
    function(from, message) {
        var rec = self.users.get(from);
        if (rec) {
            var tells = self.users.getTells(from);
            if (tells.length > 0) {
                _(tells).forEach(function(item){
                    respond("tell", from + ": " + item.from + " said '" + item.msg + "'");
                });
                self.users.clearTells(from);
            }
        };
    }]
};
