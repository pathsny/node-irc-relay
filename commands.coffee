_ = require("underscore")
require "./utils"
fs = require("fs")

class Commands
  constructor: (@users, @settings) ->

module.exports = Commands

command_definitions =


  alert:
    command: (from, tokens, cb) ->
      nick = _(tokens).head()
      user = @users.get(nick)

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
