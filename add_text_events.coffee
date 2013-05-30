_ = require "./utils"

user_modes = {
  v: "voiced user",
  h: "half operator",
  o: "operator",
  a: "administrator",
  q: "founder",
}

channel_modes = {
  n: ["permit outside messages", "prohibit outside messages"],
  t: _(["require", "not require"]).map((p) =>
    p + " operator status to change the topic"
  ),
  m: ["moderated", "not moderated"],
  i: ["invite only", "not require invitation"],
  p: ["private", "public"],
  s: ["secret", "no longer remain a secret"],
}

module.exports = (channel_name, self_nick, bot) ->
  emit_text = (t) => bot.emit 'text', t
  listeners = [{
      type: "join"
      listener: (channel, nick) =>
        emit_text "#{nick} has joined the channel"
    },{
      type: "part"
      listener: (channel, nick, reason) =>
        emit_text "#{nick} has left the channel#{if reason then " (#{reason})" else ''}"
    },{
      type: "kick"
      listener: (channel, nick, actor, reason) =>
        emit_text "#{nick} has been kicked by #{actor}#{if reason then " (#{reason})" else ''}"
    },{
      type: "quit"
      listener: (nick, message, channels) =>
        emit_text "#{nick} quit the channel (#{message})"
    },{
      type: "nick"
      listener: (oldnick, newnick) =>
        emit_text "#{oldnick} is now known as #{newnick}"
    },{
      type: "message"
      listener: (from, to, message) =>
        emit_text "<#{from}>#{message}" if channel_name is to
    },{
      type: "selfMessage"
      listener: (to, message) =>
        emit_text "<#{self_nick}> #{message}" if channel_name is to
    },{
      type: "action"
      listener: (from, to, message) =>
        emit_text "*#{from} message"
    },{
      type: "notice"
      listener: (from, to, message) =>
        emit_text "---<#{from}> #{message}" if channel_name is to
    },{
      type: "topic"
      listener: (channel, topic, nick) =>
        emit_text "#{nick} changed the channel topic to #{topic}"
    },{
      type: "raw"
      listener: (message) =>
        emit_text "#{message.nick} changed the channel topic to #{message.args[1]}" if message.command is "TOPIC"
        if message.command is "MODE" and channel_name is message.args[0]
          modes = message.args[1].split("")
          adding = modes.shift() is "+"
          other_params = message.args.slice(2)
          _(modes).each (mode) =>
            if _(["+", "-"]).include(mode)
              adding = mode is "+"
              return
            if _(user_modes).chain().keys().include(mode).value()
              emit_text "#{other_params.shift()} has been #{if adding then "promoted to " else "demoted from "} #{user_modes[mode]} by #{message.nick}"
            else if mode is "b"
              emit_text "#{message.nick} #{if adding then " set a ban on " else " removed the ban on "} #{other_params.shift()}"
            else if mode is "k"
              emit_text "#{message.nick} changed the room to #{if adding then "require a key of #{other_params.shift()}" else "not require a key"}"
            else if mode is "l"
              emit_text "#{message.nick} changed the room to #{if adding then "limit the number of users to #{other_params.shift()}" else "remove the limit on room members"}"
            else if _(channel_modes).chain().keys().include(mode).value()
              emit_text "#{message.nick} changed the room to #{if adding then channel_modes[mode][0] else channel_modes[mode][1]}"
            else
              emit_text "#{message.nick} changed the mode to #{if adding then "+" else "-"} #{mode}"
  }]
  _(listeners).each (l) -> bot.on l.type, l.listener


