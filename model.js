var userdb = require('dirty')('./data/user.db');
var uuid = require('node-uuid');
var _ = require('underscore');
require('./utils');

userdb.addIndex('nickId', function(k, v){
    return v.nickId;
});
userdb.addIndex('token', function(k, v){
    return v.token;
});

userdb.addIndex('twitter_id', function(k, v){
    return v.twitter_id;
});

userdb.listeners = [
{
    type: 'names',
    listener: function(channel, given_nicks) {
        var nicks = _(given_nicks).chain().keys().without('').map(function(nick){
            var match = /[~%](.*)/.exec(nick);
            return match ? match[1] : nick;
        }).value();
        userdb.addNicks(nicks);
        userdb.forEach(function(nick,doc) {
            if (!_(nicks).include(nick)) {
                userdb.offline(nick);
            }
            nicks = _(nicks).without(nick);
        });
    }
},
{
    type: 'join',
    listener: function(channel, nick) {
        userdb.addNick(nick);
    }
},
{
    type: 'part',
    listener: function(channel, nick) {
        userdb.offline(nick);
    }
},
{
    type: 'kick',
    listener: function(channel, nick) {
        userdb.offline(nick);
    }
},
{
    type: 'quit',
    listener: function(nick, message, channels) {
        userdb.offline(nick, message);
    }
},
{
    type: 'nick',
    listener: function(oldnick, newnick) {
        userdb.offline(oldnick);
        userdb.addNick(newnick);
        userdb.link(oldnick, newnick) || userdb.link(newnick, oldnick);
    }
},
{
    type: 'message',
    listener: function(from, to, message) {
        if (/^#/.test(to) && !_(message).automated()) {
            userdb.lastMessage(from, message);
        }
    }
}
];

userdb.link = function(nick, nickgroup) {
    var rec = userdb.get(nick);
    var recgroup = userdb.get(nickgroup);
    if (!(rec && recgroup && userdb.aliases(nick).length === 1)) return false;
    rec.nickId = recgroup.nickId;
    userdb.set(nick, rec);
    return true;
};

userdb.unlink = function(nick, nickgroup) {
    var rec = userdb.get(nick);
    var recgroup = userdb.get(nickgroup);
    if (!(rec && recgroup && rec.nickId === recgroup.nickId)) return false;
    rec.nickId = uuid();
    userdb.set(nick, rec);
    return true;
}

userdb.linkAll = function(nickgroup1, nickgroup2) {
    var rec1 = userdb.get(nickgroup1);
    var rec2 = userdb.get(nickgroup2);
    if (!(rec1 && rec2)) return false;
    _(userdb.find('nickId', rec1.nickId)).each(function(item){
        var rec = item.val;
        rec.nickId = rec2.nickId;
        userdb.set(item.key, rec)
    })
    return true;
}

userdb.addNick = function(nick) {
    var rec = userdb.get(nick);
    if (rec) {
        if (rec.status === 'online') return rec;
        rec.status = 'online';
        rec.lastSeen = new Date().getTime();
        userdb.set(nick, rec);
        return rec;
    };
    rec = {lastSeen: new Date().getTime(), timeSpent: 0, nickId: uuid(), status: 'online'};
    userdb.set(nick,rec)
    return rec;
};

userdb.online = function(nick) {
    var rec = userdb.get(nick);
    if (rec.status === 'online') return;
    rec.status = 'online';
    rec.lastSeen = new Date().getTime();
    userdb.set(nick, rec);
};


userdb.lastMessage = function(nick, message) {
    var rec = userdb.get(nick);
    rec.status = 'online';
    var time = new Date().getTime();
    rec.timeSpent = time - rec.lastSeen;
    rec.lastSeen = time;
    rec.lastMessage = {
        msg: message,
        time: time
    };
    userdb.set(nick, rec);
}

userdb.offline = function(nick, quitMsg) {
    var rec = userdb.get(nick);
    if (!rec) {
        console.log('error');
        console.log(nick);
        console.log(rec);
        return
    }
    if (rec.status === 'offline') return;
    rec.status = 'offline';
    rec.quitMsg = quitMsg;
    var time = new Date().getTime();
    rec.timeSpent = time - rec.lastSeen;
    rec.lastSeen = time;
    userdb.set(nick, rec);
};

userdb.addNicks = function(nicks) {
    _(nicks).each(function(nick){
        userdb.addNick(nick);
    })
};

userdb.aliases = function(nick) {
    var rec = userdb.get(nick);
    return userdb.find('nickId', rec.nickId);
};

userdb.aliasedNicks = function(nick) {
    if (!userdb.get(nick)) return undefined;
    return _(userdb.aliases(nick)).pluck('key');
};

_(["msg", "tell"]).each(function(type){
    userdb['add' + _(type).capitalize()] = function(nick, data) {
        var rec = userdb.get(nick);
        var collection = rec[type + 's'] || [];
        collection.push(data);
        rec[type + 's'] = collection;
        if (type === 'msg') rec.newMsgs = true;
        userdb.set(nick, rec);
    }
});

_(["msgs", "tells"]).each(function(type){
    userdb['get' + _(type).capitalize()] = function(nick) {
        return _(this.aliases(nick)).chain().map(function(item){
           return item.val[type] || []; 
        }).flatten().value();
    }
});

userdb.unSetNewMsgFlag = function(nick) {
    var newMsgExists = false;
    _(this.aliases(nick)).each(function(item){
        var rec = item.val;
        if (rec.newMsgs) newMsgExists = true;
        rec.newMsgs = false;
        userdb.set(item.key, rec);
    });
    return newMsgExists;
}

userdb.deleteMsg = function(nick, number) {
    return _(this.aliases(nick)).any(function(item){
        var msgs = item.val.msgs || [];
        if (msgs.length > number) {
            msgs.splice(number, 1);
            userdb.set(item.key, item.val);
            return true
        } else number -= msgs.length
    });
};

userdb.clearTells = function(nick) {
    _(this.aliases(nick)).each(function(item){
        var rec = item.val;
        rec.tells = [];
        userdb.set(item.key, rec);
    });
};

userdb.createToken = function(nick) {
    var rec = userdb.get(nick);
    if (rec.status !== 'online') return;
    rec["token"] = uuid();
    userdb.set(nick, rec);
    return rec["token"];
};

userdb.validToken = function(token) {
    if (!token) return;
    return _(userdb.find('token', token)).first();
};

userdb.clearProperty = function(propName, nick) {
    _(this.aliases(nick)).find(function(item){
        var rec = item.val;
        delete rec[propName];
        userdb.set(item.key, rec);
    });
};

userdb.setProperty = function(propName, nick, propValue) {
    userdb.clearProperty(propName, nick);
    var rec = userdb.get(nick);
    rec[propName] = propValue;
    userdb.set(nick, rec);
};

userdb.getProperty = function(propName, nick) {
    var rec = _(this.aliases(nick)).find(function(item){
        return item.val[propName];
    });
    return rec && rec.val[propName];
}


_(["PhoneNumber", "TwitterAccount", "EmailAddress"]).each(function(thing){
    userdb["clear" + thing] = _.bind(userdb.clearProperty, userdb, thing);
    userdb["set" + thing] = _.bind(userdb.setProperty, userdb, thing);
    userdb["get" + thing] = _.bind(userdb.getProperty, userdb, thing);
});

exports.start = function(fn) {
    userdb.on('load', function(){
        fn(userdb);
    });
};