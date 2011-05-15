var _ = require('underscore');
require('./utils');

var Commands = exports.Commands = function(users, settings) {
    if (!(this instanceof Commands)) return new Commands(users, settings);
    this.users = users;
    this.settings = settings;
}
    
Commands.prototype.commands = function(from, tokens, cb) {
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
    
    var url = 'https://ajax.googleapis.com/ajax/services/search/web?' + _({q: msg, v: "1.0", key: this.settings["google_key"], start: requestNumber}).stringify();
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
            _.parse(result.content, function(content){
                cb(result.titleNoFormatting + "   " + result.unescapedUrl + "  " + _(content).text() + " ... Result " + resNumber + " out of " + res.cursor.estimatedResultCount);
            });
        }
    });        
};

Commands.prototype.a = function(from, tokens, cb) {
    var search_tokens;
    if (/^\d+$/.test(_(tokens).head())) {
        var number = _(tokens).head();
        search_tokens = _(tokens).tail();
    } else {
        var number = undefined;
        search_tokens = tokens;
    };
    
    if (search_tokens.length === 0) {cb("a! <anime name>"); return}
    var exact_msg = "\\" + search_tokens.join(' ');
    var long_tokens = _(search_tokens).filter(function(token){return token.length >= 4});
    var short_tokens = _(search_tokens).filter(function(token){return token.length < 4});
    var msg = _(long_tokens).chain().map(function(token){return "+" + token}).concat( 
        _(short_tokens).map(function(token){return "%" + token + "%"})).value().join(' ');
    
    var anidb_info = function(title) {
        var english_name =  _(title).chain().select('title[lang="en"][type="official"]').text().value() ||
        _(title).chain().select('title[lang="en"][type="syn"]').first().text().value() ||
        _(title).chain().select('title[lang="x-jat"][type="syn"]').first().text().value();
        var main = _(title).chain().select('title[type="main"]').text().value();
        var exact = _(title).chain().select('title[exact]').first().text().value();
        var msg = main;
        if (exact != main) {msg = exact + " offically known as " + msg};
        if (english_name && english_name != exact) {msg += " (" + english_name + ")"};
        cb(msg + ". http://anidb.net/perl-bin/animedb.pl?show=anime&aid=" + title.attribs['aid']);
        
    }
    
    var parse_results = function(titles, size) {
        var extra_msg = size > 7 ? " or others." : ".";

        if (size === 0) cb("No Results");
        else if (size === 1) anidb_info(titles.first().value());
        else if (number && number <= size) anidb_info(titles.value()[number - 1])
        else cb(_(search_tokens).join(' ') + " could be " + titles.first(7).numbered().map(function(ttl){
            return ttl[0] + ". " + _(ttl[1]).chain().select('title[exact]').first().text().value();
        }).join(', ').value() + extra_msg);
    }
    
    var inexactMatch = function() {
        var url = "http://anisearch.outrance.pl/?" + _({task: 'search', query: msg}).stringify();
        _.parseRequest({uri:url}, function (error, $) {
            if (!error) {
                var titles = $('anime');
                var size = titles.size().value();
                parse_results(titles, size);
            }
        });
    }
    
    var exact_Match = function() {
        var url = "http://anisearch.outrance.pl/?" + _({task: 'search', query: exact_msg}).stringify();
        _.parseRequest({uri:url}, function (error, $) {
            if (!error) {
                var titles = $('anime');
                var size = titles.size().value();
                if (size > 0) parse_results(titles, size);
                else {
                    inexactMatch();
                }
            }
        });    
    }
    
    if (/^~$/.test(search_tokens[0]) && search_tokens.length > 1) inexactMatch();
        else exact_Match();
};

Commands.prototype.tell = function(from, tokens, cb) {
    var to = _(tokens).head();
    var msg = _(tokens).tail().join(' ');
    if (!(to && msg)) {
        cb("Message not understood");
    } else if(!this.users.get(to)) {
        cb(to + " is not known");
    } else {
        this.users.addTell(to, {from: from, msg: msg, time: Date.now()});
        cb(from + ": Message Noted");
    }
};

Commands.prototype.seen = function(from, tokens, cb) {
    var person = _(tokens).head();
    if (!person) cb("!seen needs a person to have been seen");
    else if (!this.users.get(person)) {
        cb(person + " is not known");
    } else {
        var aliases = this.users.aliases(person);
        var online_aliases = _(aliases).filter(function(item){
            return item.val.status === 'online';
        });
        if (online_aliases.length > 0) {
            var msg = person + " is online";
            if (online_aliases.length > 1 || _(online_aliases).first().key !== person)
            msg += " as " + _(online_aliases).chain().pluck('key').sentence().value();
        } else {
            var lastOnline = _(aliases).max(function(item){
                return item.val.lastSeen;
            });
            var msg = person + " was last seen online";
            if (person !== lastOnline.key) {msg += " as " + lastOnline.key}
            msg += " " + _.date(lastOnline.val.lastSeen).fromNow();
            if (lastOnline.val.quitMsg) {msg += " and quit saying " + lastOnline.val.quitMsg;}
        }
        var lastSpoke = _(aliases).max(function(item) {
            if (!item.val.lastMessage) return 0;
            return item.val.lastMessage.time;
        });
        if (lastSpoke && lastSpoke.val.lastMessage) {
            var lastMessage = lastSpoke.val.lastMessage;
            msg += " and " + _.date(lastMessage.time).fromNow() + " I saw ";
            msg += _.displayChatMsg(lastSpoke.key, lastMessage.msg);
        };
        cb(msg);
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
        if (_(message).automated()) return;
        var rec = self.users.get(from);
        if (rec) {
            var tells = self.users.getTells(from);
            if (tells.length > 0) {
                _(tells).forEach(function(item){
                    var msg = from + ": " + item.from + " said '" + item.msg + "'";
                    if (item.time) {msg += " " + _.date(item.time).fromNow()}
                    respond("tell", msg);
                });
                self.users.clearTells(from);
            }
        };
    },
    function(from, message){
        var ytube_match = /https?:\/\/www\.youtube\.com\/watch\?v=([^\s\t&]*)(?:.*?)\b/.exec(message) || 
        /https?:\/\/youtu\.be\/([^\s\t&\/]*)/.exec(message);
        if (!ytube_match) return;
        var url = "http://gdata.youtube.com/feeds/api/videos/" + ytube_match[1] + "?" + _({v: 2,alt: 'jsonc'}).stringify();
        _.request({uri:url}, function (error, response, body) {
            if (!error && response.statusCode == 200) {
                var res = JSON.parse(body).data;
                respond("ytube_metadata", "ah " + from + " is talking about " + _(res.category).articleize() + " video of " + res.title + ". The Tags are "  + _(res.tags).sentence() + ".");
            };
        });
    },
    function(from, message) {
        var anidb_match = /http:\/\/anidb\.net\/perl-bin\/animedb.pl\?(?:.*)aid=(\d+)(?:.*)/.exec(message);
        if (!anidb_match) return;
        var url = "http://api.anidb.net:9001/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=" + anidb_match[1];
        _.parseRequest({uri: url, cache: anidb_match[1]}, function(err, $){
            if (!err) {
                var english_name =  $('titles title[xml:lang="en"][type="official"]').text().value() ||
                $('titles title[xml:lang="en"][type="synonym"]').first().text().value() ||
                $('titles title[xml:lang="x-jat"][type="synonym"]').first().text().value();
                var msg = $('titles title[type="main"]').text().value();
                if (english_name) {msg += " (" + english_name + ")"};
                respond("anidb_metadata", "That anidb link is " + msg);
            }
        });
    }
    ]
};
