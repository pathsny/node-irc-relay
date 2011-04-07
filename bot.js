var sys = require('sys');
var irc = require('irc');
var channel = "#animestan";
var incoming = 'message' + channel;

function make_client(server) {
    var client = new irc.Client(server, 'ze_bot', {
        channels: [channel],
    });
    client.addListener('error', function(message) {
        sys.puts('ERROR: ' + server + ' : '+ message.command + ': ' + message.args.join(' '));
    });
    return client;
}

function relay(client_1, client_2) {
    client_1.addListener(incoming, function(from, message) {
        if (!(/^path.*/).test("path[l]")) {
            client_2.say(channel, from + ': ' + message);
        }
    })
};

var immortal_anime = make_client('irc.immortal-anime.net');
var rizon = make_client('irc.rizon.net');

relay(immortal_anime, rizon);
relay(rizon, immortal_anime);




