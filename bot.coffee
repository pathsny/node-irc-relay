irc = require("irc")
_ = require("underscore")
require("./utils")
model = require("./model")
Commands = require("./commands")
PrivateCommands = require("./private_commands")
twitter = require("./twitter").Twitter
webserver = require("./web/app").Server
fs = require("fs")
settings = JSON.parse(fs.readFileSync("./data/settings.json", "ascii"))
server = settings["server"]
channel = settings["channel"]
incoming = "message" + channel
nick = settings["nick"]
IrcToText = require("./irc_to_text")
ircToText = new IrcToText(channel)
ircLogger = require("./irc_log").Logger(ircToText)
gtalk = require("./gtalk").gtalk
Modules = require('./modules')
model.start (users) ->
  channel_say = (message) ->
    bot.say channel, message
  make_client = ->
    _(new irc.Client(server, nick,
      channels: [channel]
    )).tap (client) ->
      client.addListener "error", (message) ->
        console.error "ERROR: " + server + " : " + message.command + ": " + message.args.join(" ")

      client.say = _.wrap(client.say, (say) ->
        say.apply client, _(arguments).slice(1)
        client.emit "message", client.nick, arguments[1], arguments[2]
      )

  dispatch = (command, from, tokens) ->
    if typeof (commands[command]) is "function"
      commands[command] from, tokens, (result, dont_misakify) ->
        channel_say (if dont_misakify then result else misakify(command, result))  if result

  misaka_adjectives = JSON.parse(fs.readFileSync("./misaka_adjectives.json", "ascii"))
  misakify = (command, result) ->
    adjectives = misaka_adjectives["generic"]
    result + ", said " + bot.nick + " " + _(adjectives).rand()

  misaka_say = (msg, dont_misakify) ->
    return unless msg
    channel_say (if dont_misakify then msg else misakify('', msg))

  modules = new Modules(users, settings, misaka_say)

  commands = _({}).extend(new Commands(users, settings), modules.commands)
  private_commands = new PrivateCommands(users, settings)
  bot = make_client()
  bot.addListener "registered", ->
    bot.say "nickserv", "identify " + settings["server_password"]

  _(modules.message_listeners).each (l) ->
    bot.addListener(incoming, l)
    bot.addListener("action", (from, to, msg) => l(from, msg) if to is channel)

  last_msg_time = new Date().getTime()
  detectCommand = (from, message) ->
    last_msg_time = new Date().getTime()
    tokens = message.split(" ")
    match = /^!(.*)/.exec(_(tokens).head())
    dispatch match[1], from, _(tokens).tail()  if match

  bot.addListener incoming, detectCommand
  bot.addListener "pm", (from, message) ->
    last_msg_time = new Date().getTime()
    tokens = message.split(" ")
    command = _(tokens).head()
    if typeof (private_commands[command]) is "function"
      private_commands[command] from, _(tokens).tail(), (reply) ->
        bot.say from, reply


  _(users.listeners).chain().concat(ircToText.listeners()).each (model_listener) ->
    bot.addListener model_listener.type, model_listener.listener

  _(commands.listeners((command, message) ->
    channel_say misakify(command, message)
  )).each (listener) ->
    bot.addListener incoming, listener

  # if (settings['twitter']) {
  #     // new twitter(users, settings['twitter'],function(message){
  #     //     channel_say(misakify("twitter", message));
  #     // });
  # }
  if settings.gmail
    gtalk.configure_with users, (message) ->
      channel_say message

    gtalk.login settings.gmail

  bot.conn.setTimeout 180000, ->
    console.log "timeout"
    bot.conn.end()
    process.exit()

  compactDB = ->
    idle_time = new Date().getTime() - last_msg_time
    if users.redundantLength > 200 and idle_time > 60000
      console.log "compacting"
      users.compact()
    setTimeout compactDB, 60000

  setTimeout compactDB, 60000
  web = webserver(users, nick, settings["port"], ircToText, (from, message) ->
    channel_say from + message
    detectCommand from, message
  )

  # exit_conditions = ['SIGHUP', 'SIGQUIT', 'SIGKILL', 'SIGINT', 'SIGTERM']
  exit_conditions = ["SIGHUP", "SIGQUIT", "SIGINT", "SIGTERM"]
  exit_conditions.push "uncaughtException"  if settings["catch_all_exceptions"]
  _(exit_conditions).each (condition) ->
    process.on condition, (err) ->
      console.log condition, err
      process.exit()



