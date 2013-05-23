_ = require('../utils')
help = "add or remove a twitter account to follow. Usage !twitter add <twitter id> to start following this id. !twitter remove <twitter id> to stop following this id"

class Twitter
  constructor: ({@users, @emitter}) ->
    @users.defineScalarProperty "TwitterAccount"
    @commands = {twitter: @command}
    @command._help = help

  command: (from, tokens, cb) =>
    switch _(tokens).head()
      when "add"
        if tokens[1] then @follow(from, tokens[1], cb) else cb(help)
      when "remove"
        @unfollow from, cb
      else
        cb help

  unfollow: (from, cb) =>
    @users.clear_TwitterAccount from
    cb "clearing twitter account associated with #{from}"

  follow: (from, twitter_name, cb) =>
    uri = "http://api.twitter.com/1/users/lookup.json?screen_name=#{twitter_name}"
    _.request {uri: uri}, (error, response, body) =>
      user_data = _(JSON.parse(body)).find(({screen_name}) => screen_name is twitter_name)
      return cb "cannot find the user called #{twitter_name}" unless user_data
      @users.set_TwitterAccount from, user_data['id']
      cb "following user called #{twitter_name} with id #{user_data["id"]}"
      if user_data.status?.text
        tweet = user_data.status.text.split(/\r\n|\n/).join(' ')
        cb "whose last tweet was #{tweet}"

module.exports = Twitter