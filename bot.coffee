_ = require("./utils")
webserver = require("./web/app")
fs = require("fs")
settings = JSON.parse(fs.readFileSync("#{__dirname}/data/settings.json", "ascii"))
IrcToText = require("./irc_to_text")
ircToText = new IrcToText(settings['channel'], settings['nick'])
ircLogger = require("./irc_log").Logger(ircToText)
Modules = require('./modules')
users = require("./model")
modules = new Modules(users, settings)
create_bot = require('./create_bot')

users.on 'load', ->
  bot = create_bot(settings)
  _(users.listeners).each (l) -> bot.on l.type, l.listener
  _(ircToText.listeners()).each (l) -> bot.on l.type, l.listener
  modules.initialize(bot)

  bot.on "error", (message) ->
    console.error "ERROR: #{settings["server"]} : #{message.command} : #{message.args.join(' ')}"

  bot.conn.setTimeout 180000, ->
    console.log "timeout"
    bot.conn.end()
    process.exit()

  # web = webserver(users, nick, settings["port"], ircToText, (from, message) ->
  #   channel_say from + message
  #   detectCommand from, message
  # )
  # exit_conditions = ['SIGHUP', 'SIGQUIT', 'SIGKILL', 'SIGINT', 'SIGTERM']
  exit_conditions = ["SIGHUP", "SIGQUIT", "SIGINT", "SIGTERM"]
  exit_conditions.push "uncaughtException"  if settings["catch_all_exceptions"]
  _(exit_conditions).each (condition) ->
    process.on condition, (err) ->
      console.log condition, err
      process.exit()



