var irc = require('irc');
var _ = require('./underscore');
var model = require('./model.js');
var commands_lib = require('./commands');

var fs = require('fs');
var settings = JSON.parse(fs.readFileSync('./data/settings.json',"ascii"));

var server = settings["server"];
var channel = settings["channel"];
var incoming = 'message' + channel;
var nick = settings["nick"];

model.start(function(users){
    var commands = commands_lib.Commands(users);
    
    function channel_say(message) {
        bot.say(channel, message)
    }

    function make_client() {
        var client = new irc.Client(server, nick, {
            channels: [channel],
        });
        client.addListener('error', function(message) {
            console.error('ERROR: ' + server + ' : '+ message.command + ': ' + message.args.join(' '));
        });
        return client;
    };

    var bot = make_client();

    function dispatch(command, from, tokens) {
        if (typeof(commands[command]) === 'function') {
            commands[command](from, tokens, function(result) {
                if (result) channel_say(misakify(command, result));
            });
        }
    };

    bot.addListener(incoming, function(from, message) {
        var tokens = message.split(' ');
        var first = _(tokens).head();
        var match = /(.*)!/.exec(first);
        if (match) {
            dispatch(match[1], from, _(tokens).tail())
        };
    });

    var misaka_adjectives = JSON.parse(fs.readFileSync('./misaka_adjectives.json',"ascii"));
    var misakify = function(command, result) {
        var adjective = misaka_adjectives[command] || misaka_adjectives['generic'];
        return result + " said " + nick + ' ' + adjective;
    }
    
    _(users.listeners).each(function(model_listener){
        bot.addListener(model_listener.type, model_listener.listener);
    });

    _(commands.listeners(function(command, message){
        channel_say(misakify(command, message));
    })).each(function(listener){
        bot.addListener(incoming, listener);
    });
})



