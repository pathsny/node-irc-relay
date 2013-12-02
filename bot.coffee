require('newrelic');
_ = require("./utils")
fs = require("fs")
settings = JSON.parse(fs.readFileSync("#{__dirname}/data/settings.json", "ascii"))
Modules = require('./modules')
{app, start_webserver} = require("./web/app")
users = require("./model")
modules = new Modules(users, settings, app)
create_bot = require('./create_bot')

users.on 'load', ->
  bot = create_bot(settings)
  _(users.listeners).each (l) -> bot.on l.type, l.listener
  modules.initialize(bot, app)
  start_webserver(settings.port)

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


