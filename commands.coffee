_ = require("underscore")
require "./utils"
Email = require("./email")
gtalk = require("./gtalk").gtalk
fs = require("fs")

class Commands
  constructor: (@users, @settings) ->

module.exports = Commands

directedMessage = (from, tokens, cb, users, success) ->
  to = _(tokens).head()
  msg = _(tokens).tail().join(" ")
  unless to and msg
    cb "Message not understood"
  else unless users.get(to)
    cb to + " is not known"
  else
    success to,
      from: from
      msg: msg
      time: Date.now()

    cb from + ": Message Noted"

command_definitions =

  msg:
    command: (from, tokens, cb) ->
      users = @users
      directedMessage from, tokens, cb, users, (nick, data) ->
        users.addMsg nick, data


    _help: "stores a message in a user's message box for him/her to retrieve later at leisure. Ideal for links/images that cannot be opened on phones"

  alert:
    command: (from, tokens, cb) ->
      nick = _(tokens).head()
      user = @users.get(nick)
      if not nick or tokens.length <= 1
        cb "alert <nick> message"
        return
      else unless user
        cb "alert requires the nick of a valid user in the channel"
        return
      email_address = @users.get_EmailAddress(nick)
      message = "<" + from + "> " + _(tokens).tail().join(" ")
      unless email_address
        if gtalk.tryAlert(nick, message)
          cb "sent a gtalk alert to " + nick
        else
          cb nick + " has not configured any alert options"
      else
        gtalk.tryActiveAlert nick, message, _((result) ->
          if result
            cb "sent a gtalk alert to " + nick
            return
          unless @_email
            @_email = new Email(
              user: @settings.gmail.user
              pass: @settings.gmail.password
              clientName: "Misaka Alerts"
            )
          @_email.send
            text: message
            to: nick + " <" + email_address + ">"
            subject: "Alert Email from " + from
          , (err) ->
            if err
              cb "sorry an error occured"
            else
              cb "sent an email alert to " + nick

        ).bind(this)

    _help: "send an alert to a member of the group who has added their email address to me. alert <nick> message"

  twitter:
    command: (from, tokens, cb) ->
      self = this
      follow = (user, twitter_name) ->
        unless twitter_name
          cb "Mention which twitter user to follow. usage !twitter add <twitter id> to start following this id."
          return
        _.request
          uri: "http://api.twitter.com/1/users/lookup.json?screen_name=" + twitter_name
        , (error, response, body) ->
          user_data = _(JSON.parse(body)).find((data) ->
            data.screen_name is twitter_name
          )
          if user_data
            self.users.set_TwitterAccount from, user_data["id"]
            self.users.emit "twitter follows changed"
            msg = "following user called " + twitter_name + " with id " + user_data["id"]
            cb msg
            if user_data["status"] and user_data["status"]["text"]
              tweet = user_data["status"]["text"].split(/\r/)
              cb "whose last tweet was " + tweet[0]
              _(tweet).chain().tail().each (part) ->
                cb part

          else
            cb "cannot find the user called " + twitter_name


      unfollow = (user) ->
        self.users.clear_TwitterAccount from
        self.users.emit "twitter follows changed"

      switch _(tokens).head()
        when "add"
          follow from, tokens[1]
        when "remove"
          unfollow from
        else
          cb "usage !twitter add <twitter id> to start following this id. !twitter remove <twitter id> to stop following this id"

    _help: "add or remove a twitter account to follow. Usage !twitter add <twitter id> to start following this id. !twitter remove <twitter id> to stop following this id"

Commands::commands = Commands::help
_(command_definitions).chain().keys().each (commandName) ->
  command_definition = command_definitions[commandName]
  Commands::[commandName] = command_definition["command"]
  Commands::[commandName]._help = command_definition["_help"]

Commands::listeners = (respond) ->
  self = this

  # convey messages
  [(from, message) ->
    return  if _(message).automated()
    respond "tell", from + ": There are new Messages for you. Msg me to retrieve them"  if self.users.unSetNewMsgFlag(from)
  ]
