#exposes information about the nickname tracking the bot does and allows users to manipulate it.

class Nicks
  constructor: ({@users}) ->
    @commands = ['nick', 'link', 'unlink'].reduce (c_list, name) =>
      c_list[name] = (from, tokens, cb) => cb @[name](tokens...)
      c_list[name]._help = @help[name]
      c_list
    ,{}

  help:
    nick: "lists all the nicknames a user has used in the past"
    link: "links a nickname to any nickname from an existing set of nicknames. You can only link an unlinked nickname to other nicknames. usage !link nick1 nick2"
    unlink: "unlink a nickname from an existing group of nicknames"

  nick: (user) =>
    return "it's nick! <username> " unless user
    aliases = @users.aliasedNicks(user)
    return "#{user} is not known" unless aliases
    if aliases.length is 1
      "#{user} has only one known nick"
    else
      "known nicks of #{user} are #{_(aliases).sentence()}"

  link: (nick, group) =>
    return "link <nick> <group>" unless nick and group
    result = @users.link(nick, group)
    if result
      "#{nick} has been linked with #{group}"
    else
      "link only known UNLINKED nicks with other nicks"

  unlink: (nick, group) =>
    return "unlink <nick> <group>" unless nick and group
    result = @users.unlink(nick, group)
    if result
      "#{nick} has been unlinked from #{group}"
    else
      "unlink linked nicks"


module.exports = Nicks