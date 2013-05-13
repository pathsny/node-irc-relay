directed_message = require "#{__dirname}/base/directed_message"
_ = require('../utils')

class Tell
  constructor: (@users, settings, @emitter) ->
    @users.defineArrayProperty 'tell'
    @commands = {tell: @command}
    @message_listeners = [@message_listener]
    @command._help = "publically passes a message to a user whenever he/she next speaks. usage: !tell <user> <message>"

  command: (from, tokens, cb) =>
    directed_message from, tokens, cb, @users, (nick, data) =>
      @users.add_tell nick, data

  message_listener: (from, message) =>
    rec = @users.get(from)
    return if _(message).automated() || !rec
    tells = @users.get_tells(from)
    return if _(tells).isEmpty()
    _(tells).each (item) =>
      @emitter "#{from}: #{item.from} said '#{item.msg}' #{_.date(item.time).fromNow()}"
    @users.clear_tells from

module.exports = Tell