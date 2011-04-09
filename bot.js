var sys = require('sys');
var irc = require('irc');
var _ = require('./underscore');
var commands = require('./commands')

var channel = "#animestan-hell";
var incoming = 'message' + channel;
var nick = 'amelia';

function make_client(server) {
    var client = new irc.Client('irc.immortal-anime.net', nick, {
        channels: [channel],
    });
    client.addListener('error', function(message) {
        sys.puts('ERROR: ' + server + ' : '+ message.command + ': ' + message.args.join(' '));
    });
    return client;
}

var bot = make_client();

function dispatch(command, tokens) {
    if (typeof(commands[command]) === 'function') {
        commands[command](tokens, function(result) {
            sys.puts('fuwa ' + result);
            if (result) bot.say(result);
        });
    }
}

bot.addListener(incoming, function(from, message) {
    var tokens = message.split(' ');
    var first = _(tokens).head();
    if (first === nick) {
        var msg_tokens = _(tokens).tail();
        dispatch(_(msg_tokens).head(), _(msg_tokens).tail())
    };
    var match = /(.*)!/.exec(first);
    if (match) {
        dispatch(match[1], _(tokens).tail())
    };
})