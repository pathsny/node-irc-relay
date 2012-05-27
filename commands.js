var _ = require('underscore');
require('./utils');
var PEG = require("pegjs");
var fs = require('fs');
var parser = PEG.buildParser(fs.readFileSync('log_request.js',"ascii"));
var anidb = require('./anidb');
var email = require('./email');
var gtalk = require('./gtalk').gtalk;

var Commands = exports.Commands = function(users, settings) {
    if (!(this instanceof Commands)) return new Commands(users, settings);
    this.users = users;
    this.settings = settings;
}

var directedMessage = function(from, tokens, cb, users, success) {
    var to = _(tokens).head();
    var msg = _(tokens).tail().join(' ');
    if (!(to && msg)) {
        cb("Message not understood");
    } else if(!users.get(to)) {
        cb(to + " is not known");
    } else {
        success(to, {from: from, msg: msg, time: Date.now()});
        cb(from + ": Message Noted");
    }
}

var command_definitions = {
    help: {
        command: function(from, tokens, cb) {
            if (_(tokens).isEmpty()) {
                cb("I know " + _(Commands.prototype).chain().keys().
                difference(["listeners", "private", "commands", "help"]).
                map(function(command){
                    return "!" + command;
                    }).
                    sentence().value());
                cb("Type !help <command> to know more about any command");
            } else {
                var command = Commands.prototype[_(tokens).chain().
                head().
                firstMatchIfExists(/!(.*)/).value()];
                var helpCommand = command ? (command["_help"] || "I have no help on this command") : "No Such Command";
                cb((typeof helpCommand === 'function') ? helpCommand.call() : helpCommand);
            }
        }
    },
   video: {
       command: function(from, tokens, cb) {
           cb(this.settings["baseURL"] + ":" + this.settings["port"] + '/video');
       },
       _help: "Video chat with other people in the channel"
   },
   logs: {
       command: function(from, tokens, cb) {
           var url = this.settings["baseURL"] + ":" + this.settings["port"];
           if (_(tokens).head() === 'now') cb(url + "/#" + _.now(true))
           else if (_(tokens).head() === 'q') cb(url + "/search?q=" + _(tokens).tail().join('+'))
           else if (_(tokens).last() === 'ago') {
               try {
                   var time = parser.parse(_(tokens).join(' '));
                   var time_hash = _(time).inject(function(hsh, item){
                       if ((!hsh) || (item[1] in hsh)) return;
                       hsh[item[1]] = item[0];
                       return hsh;
                   },{})
                   if (time_hash)
                   cb(url + "/#" + _.now().subtract(time_hash).date.getTime())
                   else cb("that makes no sense")
               } catch (err) {
                   cb("that makes no sense")
               }
           }
           else cb("usage: !logs <x days, y hours, z mins ago> or !logs now or !logs q <search terms>")
       },
      _help: "Display logs for the channel for some point in time. usage: !logs <x days, y hours, z mins ago> or !logs now or !logs q <search terms>"
   },
   g: {
       command: function(from, tokens, cb) {
           if (/^\d+/.test(_(tokens).head())) {
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
                   cb(result.titleNoFormatting + "   " + result.unescapedUrl + "  " + _(result.content).html_as_text() + " ... Result " + resNumber + " out of " + res.cursor.estimatedResultCount);
               }
           });
       },
       _help: "search google for the terms you're looking for. !g <terms> for the first result. !g x <terms> for the xth result"
   },
   m: {
       command: function(from, tokens, cb) {
           query = tokens.join(" ").replace(/^\s+|\s+$/g, "");
           var url = "http://tinysong.com/b/" + encodeURIComponent(query) + "?" +
               _({format: "json", key: this.settings["tinysong_key"]}).stringify();
           _.request({uri:url}, function (error, response, body) {
               if (!error && response.statusCode == 200) {
                   var responseJson = JSON.parse(body);
                   if (responseJson.Url != undefined) {
                       cb("Listen to " + responseJson.ArtistName + " - " + responseJson.SongName + " at " + responseJson.Url);
                   } else {
                       cb("No song found for: " + query);
                   }
               }
           });
       },
      _help: "searches tinysong and provides a url to grooveshark to listen to the song" 
   },
   a: {
       command: function(from, tokens, cb) {
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

           var anidb_info = function(anime) {
               var englishNode =  
               _(anime.title).find(function(t){
                   return t.lang === 'en' && t.type==='official'
                  }) ||
               _(anime.title).find(function(t){
                   return t.lang === 'en' && t.type === 'syn'
               }) ||
               _(anime.title).find(function(t){
                      return t.lang === 'x-jat' && t.type === 'syn'
                  });
               var mainNode = _(anime.title).find(function(t){
                   return t.type === 'main';
               });
               var exactNode = _(anime.title).find(function(t){
                   return t.exact;
               });
               var msg = mainNode['#'];
               if (exactNode != mainNode) {msg = exactNode['#'] + " offically known as " + msg};
               if (englishNode && englishNode != exactNode) {msg += " (" + englishNode['#'] + ")"};
               cb(msg + ". http://anidb.net/perl-bin/animedb.pl?show=anime&aid=" + anime['aid']);
               anidb.getInfo(anime['aid'], function(data){
                   cb(data.splitDescription);
               });
           }

           var parse_results = function(animes) {
               if (!_(animes).isArray()) animes = [animes];
               var size = animes.length;
               var extra_msg = size > 7 ? " or others." : ".";
               if (size === 0) cb("No Results");
               else if (size === 1) anidb_info(animes[0]);
               else if (number && number <= size) anidb_info(animes[number - 1])
               else cb(_(search_tokens).join(' ') + " could be " + _(animes).chain().first(7).numbered().map(function(ttl){
                   return ttl[0] + ". " + _(ttl[1].title).find(function(t){return t.exact})['#'];
               }).join(', ').value() + extra_msg);
           }

           var inexactMatch = function() {
               var url = "http://anisearch.outrance.pl/?" + _({task: 'search', query: msg}).stringify();
               _.requestXmlAsJson({uri:url}, function (error, data) {
                   if (error) {console.error(error)}
                    else {
                       var animes = data['anime'];
                       if (animes) parse_results(animes);
                   }
               });
           }

           var exact_Match = function() {
               var url = "http://anisearch.outrance.pl/?" + _({task: 'search', query: exact_msg}).stringify();
               _.requestXmlAsJson({uri:url}, function (error, data) {
                   if (error) {console.error(error)}
                    else {
                       var animes = data['anime'];
                       if (animes) parse_results(animes);
                       else inexactMatch();
                   }
               });
           }

           if (/^~$/.test(search_tokens[0]) && search_tokens.length > 1) inexactMatch();
               else exact_Match();
       },
      _help: "search anidb for the anime that matches the terms. !a <name> lists all the matches, or the show if there is only one match. !a x <name> gives you the xth match." 
   },
   tell: {
       command: function(from, tokens, cb) {
           var users = this.users;
           directedMessage(from, tokens, cb, users, function(nick, data) {
               users.addTell(nick, data);
           });
       },
        _help: "publically passes a message to a user whenever he/she next speaks. usage: !tell <user> <message>"
    },
    msg: {
        command: function(from, tokens, cb) {
            var users = this.users;
            directedMessage(from, tokens, cb, users, function(nick, data) {
                users.addMsg(nick, data);
            });
        },
        _help: "stores a message in a user's message box for him/her to retrieve later at leisure. Ideal for links/images that cannot be opened on phones"
        
    },
    seen: {
        command: function(from, tokens, cb) {
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
        },
        _help: "let's you know when a user was last seen online and last spoke in the channel. Also should end up triggering his/her nick alert ;) "
    },
    nick: {
        command: function(from, tokens, cb) {
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
        },
        _help: "lists all the nicknames a user has used in the past"
    },
    link: {
        command: function(from, tokens, cb) {
            var nick = _(tokens).head();
            var group = _(tokens).chain().tail().head().value();
            if (!(nick && group)) {
                cb("link <nick> <group>");
            } else {
                var result = this.users.link(nick, group);
                if (result) cb(nick + " has been linked with " + group);
                    else cb('link only known UNLINKED nicks with other nicks');
            }
        },
        _help: "links a nickname to any nickname from an existing set of nicknames. You can only link an unlinked nickname to other nicknames. usage !link nick1 nick2"
    },
    unlink: {
        command: function(from, tokens, cb) {
            var nick = _(tokens).head();
            var group = _(tokens).chain().tail().head().value();
            if (!(nick && group)) {
                cb("unlink <nick> <group>");
            } else {
                var result = this.users.unlink(nick, group);
                if (result) cb(nick + " has been unlinked from " + group);
                else cb('unlink linked nicks');
            }
        },
        _help: "unlink a nickname from an existing group of nicknames"
    },
    alert: {
        command: function(from, tokens, cb) {
            var nick = _(tokens).head();
            var user = this.users.get(nick);
            if (!nick || tokens.length <= 1) {
                cb("alert <nick> message");
                return;
            } else if (!user) {
                cb("alert requires the nick of a valid user in the channel");
                return;
            } 

            var email_address = this.users.getEmailAddress(nick);
            var message = '<' + from + '> ' + _(tokens).tail().join(' ');
            
            if (!email_address) {
                if (gtalk.tryAlert(nick, message)) cb('sent a gtalk alert to ' + nick);
                else cb(nick + " has not configured any alert options");
            } else {
                gtalk.tryActiveAlert(nick, message, _(function(result){
                    if (result) {
                        cb('sent a gtalk alert to ' + nick);
                        return;
                    }
                    if (!this._email) {
                        this._email = new email.Email({
                            user: this.settings.gmail.user,
                            pass: this.settings.gmail.password,
                            clientName: 'Misaka Alerts'
                        });
                    }
                    this._email.send({
                        text: message,
                        to: nick + " <" + email_address + ">",
                        subject: "Alert Email from " + from
                    }, function(err){
                        if (err) cb("sorry an error occured");
                            else cb('sent an email alert to ' + nick);
                    });
                }).bind(this));
            }
        },
        _help: "send an alert to a member of the group who has added their email address to me. alert <nick> message"
    },
    twitter: {
        command: function(from, tokens, cb) {
            var self = this;
            var follow = function(user, twitter_name) {
                if (!twitter_name) {
                    cb('Mention which twitter user to follow. usage !twitter add <twitter id> to start following this id.');
                    return;
                }
                _.request({uri: 
                    "http://api.twitter.com/1/users/lookup.json?screen_name=" + twitter_name
                    }, function(error, response, body){
                        var user_data = _(JSON.parse(body)).find(function(data){
                            return data.screen_name === twitter_name;
                        });
                        if (user_data) {
                            self.users.setTwitterAccount(from, user_data['id']);
                            self.users.emit('twitter follows changed');
                            var msg = 'following user called ' + twitter_name + ' with id ' + user_data['id'];
                            cb(msg);
                            if (user_data['status'] && user_data['status']['text']) {
                                var tweet = user_data['status']['text'].split(/\r/)
                                cb('whose last tweet was ' + tweet[0]);
                                _(tweet).chain().tail().each(function(part){
                                    cb(part);
                                });
                            }
                        } else cb('cannot find the user called ' + twitter_name);
                    })
            };
            var unfollow = function(user) {
                self.users.clearTwitterAccount(from);
                self.users.emit('twitter follows changed');
            };
            switch (_(tokens).head()) {
                case 'add':
                    follow(from, tokens[1]) 
                    break;
                case 'remove':
                    unfollow(from);
                    break;
                default:
                cb('usage !twitter add <twitter id> to start following this id. !twitter remove <twitter id> to stop following this id');
            }
        },
        _help: 'add or remove a twitter account to follow. Usage !twitter add <twitter id> to start following this id. !twitter remove <twitter id> to stop following this id'
    }    
}

Commands.prototype.commands = Commands.prototype.help;

_(command_definitions).chain().keys().each(function(commandName){
    var command_definition = command_definitions[commandName];
    Commands.prototype[commandName] = command_definition["command"];
    Commands.prototype[commandName]._help = command_definition["_help"];
})

Commands.prototype.listeners = function(respond){
    var self = this;
    var matchers = require('./url_matchers').matchers;
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
    function(from, message) {
        if (_(message).automated()) return;
        if (self.users.unSetNewMsgFlag(from)) {
                respond("tell", from + ": There are new Messages for you. Msg me to retrieve them");
            }
    },
    function(from, message) {
        _(matchers).chain().keys().detect(function(type) {
            var matching_regex = _(matchers[type].regexes).detect(function(regex){
                return regex.test(message);
            });
            if (matching_regex) {
                matchers[type].responder(from, message, matching_regex.exec(message), function(msg){
                    respond(type + "_metadata", msg);
                });
                return true;
            }
        });
    }]
};
