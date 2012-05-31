var irc = require('irc');
var _ = require('underscore');
require('./utils');
var model = require('./model.js');
var commands_lib = require('./commands');
var private_commands_lib = require('./private_commands');
var twitter = require('./twitter').Twitter;
var webserver = require('./web/app').Server;

var fs = require('fs');
var settings = JSON.parse(fs.readFileSync('./data/settings.json',"ascii"));

var server = settings["server"];
var channel = settings["channel"];
var incoming = 'message' + channel;
var nick = settings["nick"];
var ircToText = require('./irc_to_text').IrcToText(channel);
var ircLogger = require('./irc_log').Logger(ircToText);
var gtalk = require('./gtalk').gtalk;


model.start(function(users){
    var commands = commands_lib.Commands(users, settings);
    var private_commands = private_commands_lib.Commands(users, settings);

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
    
    var detectCommand = function(from, message) {
        last_msg_time = new Date().getTime();
        var tokens = message.split(' ');
        var match = /^!(.*)/.exec(_(tokens).head());
        if (match) {
            dispatch(match[1], from, _(tokens).tail())
        };
    }
    
    bot.addListener(incoming, detectCommand);
    
    bot.addListener("pm", function(from, message) {
        last_msg_time = new Date().getTime();
        var tokens = message.split(' ');
        command = _(tokens).head();
        if (typeof(private_commands[command]) === 'function')
            private_commands[command](from, _(tokens).tail(), function(reply){
                bot.say(from, reply);
            });
    });
    
    _(users.listeners).chain().concat(ircToText.listeners()).each(function(model_listener){
        bot.addListener(model_listener.type, model_listener.listener);
    });

    _(commands.listeners(function(command, message){
        channel_say(misakify(command, message));
    })).each(function(listener){
        bot.addListener(incoming, listener);
    });
    
    if (settings['twitter']) {
        // new twitter(users, settings['twitter'],function(message){
        //     channel_say(misakify("twitter", message));
        // });
    }
    
    if (settings.gmail) {
        gtalk.configure_with(users, function(message){
            console.log(message)
            channel_say(misakify("gtalk", message));
        });
        gtalk.login(settings.gmail) 
    }
    
    var misaka_adjectives = JSON.parse(fs.readFileSync('./misaka_adjectives.json',"ascii"));
    var misakify = function(command, result) {
        var adjectives = misaka_adjectives[command] || misaka_adjectives['generic'];
        return result + " said " + bot.nick + ' ' + _(adjectives).rand();
    }
    
    bot.conn.setTimeout(180000, function(){
        console.log('timeout');
        bot.conn.end();
        process.exit();
    });
    
    var compactDB = function(){
        var idle_time = new Date().getTime() - last_msg_time;
        if (users.redundantLength > 200 && idle_time > 60000) {
            console.log('compacting');
            users.compact();
        }
        setTimeout(compactDB,60000)
    };
    
    setTimeout(compactDB,60000);
    var web = webserver(users, nick, settings["port"], ircToText, function(from, message){
        channel_say(misakify('video', from + message));
        detectCommand(from, message);
    });
    
    
    exit_conditions = ['SIGHUP', 'SIGQUIT', 'SIGKILL', 'SIGINT', 'SIGTERM']
    if (settings["catch_all_exceptions"]) {
        exit_conditions.push('uncaughtException')
    };
    _(exit_conditions).each(function(condition){
        process.on(condition, function(err){
            console.log(condition, err);
            process.exit();
        });
    });
});



