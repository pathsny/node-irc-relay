directed_message = require "#{__dirname}/base/directed_message"

standard_message = "There are new Messages for you. Msg me to retrieve them"
class MsgBox
  constructor: ({@users, @emitter}) ->
    @users.defineArrayProperty 'msg'
    @users.defineScalarProperty 'newMsgs'

    @commands = {msg: @command}
    @message_listeners = [@message_listener]
    @command._help = "stores a message in a user's message box for him/her to retrieve later at leisure. Ideal for links/images that cannot be opened on phones"
    @private_commands = {list: @list, del: @del}
    @list._help = "list : lists all messages left for you"
    @del._help = "del <x> : deletes the xth message"

  command: (from, tokens, cb) =>
    directed_message from, tokens, cb, @users, (nick, data) =>
      @users.add_msg nick, data
      @users.set_newMsgs nick, true

  message_listener: (from, message) =>
    return  if _(message).automated()
    if (@users.get_newMsgs(from))
      @emitter "#{from}: #{standard_message}"
      @users.set_newMsgs from, false

  list: (from, tokens, cb) =>
    return unless @users.get(from)
    msgs = @users.get_msgs(from)
    if msgs.length > 0
      _(msgs).chain().
      zipWithIndex().
      each ([{from, msg, time}, index]) =>
        cb "#{index + 1}. #{from} said '#{msg}' #{_.date(time).fromNow()}"
    else
      cb "There are no messages for you"

  del: (from, tokens, cb) =>
    return unless @users.get(from)
    first = _(tokens).head()
    if !first or !/^\d+$/.test(first)
      return cb("delete requires a message number to delete")
    number = Number(first)
    if @users.del_msg(from, number - 1)
      cb "message number #{number} has been deleted"
    else
      cb "there is no message number #{number}"

module.exports = MsgBox
