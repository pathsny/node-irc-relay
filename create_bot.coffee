EventEmitter = require('events').EventEmitter
irc = require("irc")
fs = require("fs")
misaka_adjectives = JSON.parse(fs.readFileSync("#{__dirname}/misaka_adjectives.json", "ascii"))
add_text_events = require("./add_text_events")

module.exports = ({channel, server, nick, server_password}) ->
  bot = new irc.Client(server, nick, {
    channels: [channel],
    floodProtection: true,
    floodProtectionDelay: 500,
  })
  add_text_events(channel, nick, bot)
  bot.addListener "registered", ->
    bot.say "nickserv", "identify #{server_password}"


  misakify = (command, result) ->
    adjectives = misaka_adjectives["generic"]
    "#{result}, said #{nick} #{_(adjectives).rand()}"

  bot.channel_say = (msg, dont_misakify) =>
    return unless msg
    bot.say channel, (if dont_misakify then msg else misakify('', msg))
  bot
