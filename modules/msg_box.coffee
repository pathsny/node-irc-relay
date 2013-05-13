directed_message = require "#{__dirname}/base/directed_message"

standard_message = "There are new Messages for you. Msg me to retrieve them"
class MsgBox
  constructor: ({@users, @emitter}) ->
    # @users.defineArrayProperty 'tell'
    @commands = {msg: @command}
    @message_listeners = [@message_listener]
    @command._help = "stores a message in a user's message box for him/her to retrieve later at leisure. Ideal for links/images that cannot be opened on phones"
    @private_commands = {list: @list, del: @del}
    @list._help = "list : lists all messages left for you"
    @del._help = "del <x> : deletes the xth message"

  command: (from, tokens, cb) =>
    directed_message from, tokens, cb, @users, (nick, data) =>
      @users.addMsg nick, data

  message_listener: (from, message) =>
    return  if _(message).automated()
    @emitter "#{from}: #{standard_message}" if @users.unSetNewMsgFlag(from)

  list: (from, tokens, cb) =>
    return unless @users.get(from)
    msgs = @users.getMsgs(from)
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
    if @users.deleteMsg(from, number - 1)
      cb "message number #{number} has been deleted"
    else
      cb "there is no message number #{number}"

module.exports = MsgBox
