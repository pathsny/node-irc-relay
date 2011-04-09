var irc = require('irc');
var _ = require('./underscore');
var commands = require('./commands')

var channel = "#animestan";
var incoming = 'message' + channel;
var nick = 'amelia';

function channel_say(message) {
    bot.say(channel, message)
}

function make_client(server) {
    var client = new irc.Client('irc.immortal-anime.net', nick, {
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
            console.log('fuwa ' + result);
            if (result) channel_say(result);
        });
    }
};

bot.addListener(incoming, function(from, message) {
    var tokens = message.split(' ');
    var first = _(tokens).head();
    if (first === nick) {
        var msg_tokens = _(tokens).tail();
        dispatch(_(msg_tokens).head(), from, _(msg_tokens).tail())
    };
    var match = /(.*)!/.exec(first);
    if (match) {
        dispatch(match[1], from, _(tokens).tail())
    };
});

_(commands.listeners(channel_say)).each(function(listener){
    bot.addListener(incoming, listener);
});
