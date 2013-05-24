irc = require("irc")
_ = require("underscore")
require("./utils")
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
Modules = require('./modules')
users = require("./model")
dummy = {}
modules = new Modules(users, settings, (args...) -> dummy.misaka_say(args...))

users.on 'load', ->
  channel_say = (message) ->
    bot.say channel, message
  make_client = ->
    _(new irc.Client(server, nick,
      channels: [channel],
      floodProtection: true,
      floodProtectionDelay: 500,
    )).tap (client) ->
      client.addListener "error", (message) ->
        console.error "ERROR: #{server} : #{message.command} : #{message.args.join(' ')}"
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

  dummy.misaka_say = (msg, dont_misakify) ->
    return unless msg
    channel_say (if dont_misakify then msg else misakify('', msg))

  commands = modules.commands
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
    if typeof (modules.private_commands[command]) is "function"
      modules.private_commands[command] from, _(tokens).tail(), (reply) ->
        bot.say from, reply


  _(users.listeners).chain().concat(ircToText.listeners()).each (model_listener) ->
    bot.addListener model_listener.type, model_listener.listener

  bot.conn.setTimeout 180000, ->
    console.log "timeout"
    bot.conn.end()
    process.exit()

  COMPACT_TIME_LIMIT = 60000
  compactDB = ->
    console.log('trying to compact');
    idle_time = new Date().getTime() - last_msg_time
    if users.redundantLength > 200 and idle_time > COMPACT_TIME_LIMIT
      console.log('compacting');
      users.once('compacted', -> setTimeout(compactDB, COMPACT_TIME_LIMIT))
      users.compact()
    else
      setTimeout(compactDB, COMPACT_TIME_LIMIT)

  setTimeout compactDB, COMPACT_TIME_LIMIT
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



