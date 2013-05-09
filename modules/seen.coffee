_ = require('../utils')

class Seen
  constructor: (@users, settings, @emitter) ->
    @commands = {seen: @command}
    @command._help = "let's you know when a user was last seen online and last spoke in the channel. Also should end up triggering his/her nick alert ;) "

  command: (from, tokens, cb) =>
    cb @parse(from, _(tokens).head())

  parse: (from, person) =>
    return "!seen needs a person to have been seen" unless person
    return "#{person} is not known" unless @users.get(person)
    aliases = @users.aliases(person)
    msg = @connection_status(person, aliases)
    if last_msg = @last_spoke(aliases)
      "#{msg} and #{last_msg}"
    else
      msg

  connection_status: (person, aliases) =>
    online_aliases = _(aliases).filter((item) => item.val.status is "online")
    if _(online_aliases).isEmpty()
      @last_online_status(person, aliases)
    else
      @online_status(person, online_aliases)

  online_status: (person, o_aliases) =>
    msg = "#{person} is online"
    if o_aliases.length == 1 and o_aliases[0].key is person
      msg
    else
      "#{msg} as #{_(o_aliases).chain().pluck("key").sentence().value()}"

  last_online_status: (person, aliases) =>
    last_online = _(aliases).max((item) => item.val.lastSeen)
    msg = "#{person} was last seen online"
    msg = "#{msg} as #{last_online.key}" if last_online.key isnt person
    msg = "#{msg} #{_.date(last_online.val.lastSeen).fromNow()}"
    return msg if (!last_online.val.quitMsg)
    "#{msg} and quit saying #{lastOnline.val.quitMsg}"

  last_spoke: (aliases) =>
    lastSpoke = _(aliases).max((item) => item.val.lastMessage?.time ? 0)
    if lastSpoke and (lastMessage = lastSpoke.val.lastMessage)
      "#{_.date(lastMessage.time).fromNow()} I saw #{_.displayChatMsg(lastSpoke.key, lastMessage.msg)}"

module.exports = Seen