var irc = require('irc');
var _ = require('underscore');
require('./utils');
var model = require('./model.js');
var commands_lib = require('./commands');

var fs = require('fs');
var settings = JSON.parse(fs.readFileSync('./data/settings.json',"ascii"));

var server = settings["server"];
var channel = settings["channel"];
var incoming = 'message' + channel;
var nick = settings["nick"];
var ircLogger = require('./irc_log').Logger(channel);


model.start(function(users){
    var commands = commands_lib.Commands(users, settings);
    
    function channel_say(message) {
        bot.say(channel, message)
    }

    function make_client() {
        return _(new irc.Client(server, nick, {
            channels: [channel]
        })).tap(function(client){
            client.addListener('error', function(message) {
                console.error('ERROR: ' + server + ' : '+ message.command + ': ' + message.args.join(' '));
            });
            client.say = _.wrap(client.say, function(say) {
                say.apply(client, _(arguments).slice(1));
                client.emit('message', client.nick, arguments[1], arguments[2]);
            });
        });
    };

    var bot = make_client();

    function dispatch(command, from, tokens) {
        if (typeof(commands[command]) === 'function') {
            commands[command](from, tokens, function(result) {
                if (result) channel_say(misakify(command, result));
            });
        }
    };
    
    bot.addListener("registered", function(){
        bot.say("nickserv", "identify " + settings["server_password"]);
    });

    var last_msg_time = new Date().getTime();
    bot.addListener(incoming, function(from, message) {
        last_msg_time = new Date().getTime();
        var tokens = message.split(' ');
        var first = _(tokens).head();
        var match = /!(.*)/.exec(first);
        if (match) {
            dispatch(match[1], from, _(tokens).tail())
        };
    });

    var misaka_adjectives = JSON.parse(fs.readFileSync('./misaka_adjectives.json',"ascii"));
    var misakify = function(command, result) {
        var adjectives = misaka_adjectives[command] || misaka_adjectives['generic'];
        return result + " said " + bot.nick + ' ' + _(adjectives).rand();
    }
    
    _(users.listeners).chain().concat(ircLogger.listeners()).each(function(model_listener){
        bot.addListener(model_listener.type, model_listener.listener);
    });

    _(commands.listeners(function(command, message){
        channel_say(misakify(command, message));
    })).each(function(listener){
        bot.addListener(incoming, listener);
    });
    
    bot.conn.setTimeout(180000, function(){
        console.log('timeout')
        bot.conn.end();
    })
    
    var compactDB = function(){
        var idle_time = new Date().getTime() - last_msg_time;
        if (users.redundantLength > 200 && idle_time > 60000) {
            console.log('compacting');
            users.compact();
        }
        setTimeout(compactDB,60000)
    };
    
    setTimeout(compactDB,60000);
});



