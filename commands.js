var _ = require('./underscore');
require('./utils');
var $ = require('jquery');

var Commands = exports.Commands = function(users, settings) {
    if (!(this instanceof Commands)) return new Commands(users, settings);
    this.users = users;
    this.settings = settings;
}
    
Commands.prototype.commands = function(from, token, cb) {
    cb("I know " + _(Commands.prototype).chain().keys().
    without("listeners").
    without("private").
    without("commands").
    map(function(command){
        return "!" + command;
    }).
    sentence().value());
};

Commands.prototype.g = function(from, tokens, cb) {
    if (/\d+/.test(_(tokens).head())) {
        var number = _(tokens).head();
        var msg = _(tokens).tail().join(' ');
    } else {
        var number = "1";
        var msg = tokens.join(' ');
    };
    
    var requestNumber = Math.floor((Number(number) - 1) / 4)*4;
    var resultIndex = Number(number) - requestNumber - 1;
    
    var url = 'https://ajax.googleapis.com/ajax/services/search/web?' + _($.param({q: msg, v: "1.0", key: this.settings["google_key"], start: requestNumber})).escape_quote();
    _.request({uri:url}, function (error, response, body) {
        if (!error && response.statusCode == 200) {
            var responseJson = JSON.parse(body);
            if (responseJson.responseStatus !== 200) {
                cb("google error '" + responseJson.responseDetails + "' ");
                return
            }
            var res = responseJson.responseData;
            var results = res.results;
            if (!results[resultIndex]) {resultIndex = results.length - 1};
            
            if (resultIndex === -1) {cb("no results! "); return}
            var result = results[resultIndex];
            var resNumber = res.cursor.currentPageIndex * 4 + resultIndex + 1;
            cb(result.titleNoFormatting + "   " + result.unescapedUrl + "  " + $(result.content).text() + " ... Result " + resNumber + " out of " + res.cursor.estimatedResultCount);
        }
    });        
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
            if (aliases.length === 1) cb(user + " has only one known nick");
            else cb("known nicks of " + user + " are " + _(aliases).sentence());
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

Commands.prototype.unlink = function(from, tokens, cb) {
    var nick = _(tokens).head();
    var group = _(tokens).chain().tail().head().value();
    if (!(nick && group)) {
        cb("unlink <nick> <group>");
    } else {
        var result = this.users.unlink(nick, group);
        if (result) cb(nick + " has been unlinked from " + group);
            else cb('unlink linked nicks');
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
    },
    function(from, message){
        var ytube_match = /http:\/\/www\.youtube\.com\/watch\?v=([^\s\t&]*)(?:.*?)\b/.exec(message) || 
        /http:\/\/youtu\.be\/([^\s\t&\/]*)/.exec(message);
        if (!ytube_match) return;
        var url = "http://gdata.youtube.com/feeds/api/videos/" + ytube_match[1] + "?" + $.param({v: 2,alt: 'jsonc'});
        _.request({uri:url}, function (error, response, body) {
            if (!error && response.statusCode == 200) {
                var res = JSON.parse(body).data;
                respond("ytube_metadata", "ah " + from + " is talking about " + _(res.category).articleize() + " video of " + res.title + ".");
                respond("ytube_metadata", "There are " + res.viewCount + " views and the Tags are "  + _(res.tags).sentence() + ". The link again is " + ytube_match[0]);
            }
        });
    },
    function(from, message) {
        var anidb_match = /http:\/\/anidb\.net\/perl-bin\/animedb.pl\?(?:.*)aid=(\d+)(?:.*)/.exec(message);
        if (!anidb_match) return;
        var url = "http://api.anidb.net:9001/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=" + anidb_match[1];
        _.request({uri: url, cache: anidb_match[1]}, function(error, response, body) {
            if (!error & response.statusCode == 200) {
                var res = $(body);
                var english_name = res.find("titles > title[xml\\:lang='en'][type='official']").html();
                if (!english_name) english_name = res.find("titles > title[xml\\:lang='en'][type='synonym']").first().html();
                if (!english_name) english_name = res.find("titles > title[xml\\:lang='x-jat'][type='synonym']").first().html();
                var msg = res.find("titles > title[type='main']").html();
                if (english_name && msg !== english_name) {msg += "    ( " + english_name + " )"}
                respond("anidb_metadata", msg);
            };
        });
    }
    ]
};
