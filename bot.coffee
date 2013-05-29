irc = require("irc")
_ = require("underscore")
require("./utils")
twitter = require("./twitter").Twitter
webserver = require("./web/app").Server
fs = require("fs")
settings = JSON.parse(fs.readFileSync("#{__dirname}/data/settings.json", "ascii"))
server = settings["server"]
channel = settings["channel"]
incoming = "message" + channel
nick = settings["nick"]
IrcToText = require("./irc_to_text")
ircToText = new IrcToText(channel, nick)
ircLogger = require("./irc_log").Logger(ircToText)
Modules = require('./modules')
users = require("./model")
EventEmitter = require('events').EventEmitter
modules = new Modules(users, settings)

users.on 'load', ->
  make_client = ->
    _(new irc.Client(server, nick,
      channels: [channel],
      floodProtection: true,
      floodProtectionDelay: 500,
    )).tap (client) ->
      client.addListener "error", (message) ->
        console.error "ERROR: #{server} : #{message.command} : #{message.args.join(' ')}"
      client.addListener "registered", ->
        client.say "nickserv", "identify #{settings["server_password"]}"


  bot = make_client()
  _(users.listeners).chain().concat(ircToText.listeners()).each (model_listener) ->
    bot.addListener model_listener.type, model_listener.listener

  modules.initialize(new Misaka(channel, bot))


  bot.conn.setTimeout 180000, ->
    console.log "timeout"
    bot.conn.end()
    process.exit()

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

class Misaka extends EventEmitter
  constructor: (@channel, @bot) ->
    bot.addListener incoming, (from, msg) => @emit('channel_msg', from, msg)
    bot.addListener 'action', (from, to, msg) => @emit('channel_msg', from, msg)
    bot.addListener 'pm', (from, msg) =>
      @emit 'pm', from, msg, (reply) -> bot.say from, reply

    @misaka_adjectives = JSON.parse(fs.readFileSync("#{__dirname}/misaka_adjectives.json", "ascii"))

  misakify: (command, result) ->
    adjectives = @misaka_adjectives["generic"]
    "#{result}, said #{@bot.nick} #{_(adjectives).rand()}"

  channel_say: (msg, dont_misakify) =>
    return unless msg
    @bot.say @channel, (if dont_misakify then msg else @misakify('', msg))



