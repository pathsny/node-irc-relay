directed_message = require "#{__dirname}/base/directed_message"
_ = require('../utils')

class Tell
  constructor: ({@users, @emitter, settings}) ->
    @users.defineArrayProperty 'tell'
    @users.defineSetProperty 'topic'
    @users.addIndex "topics", (k, v) -> v.topics || []
    @secret_password = settings['secret_password']
    @commands = {tell: @tell, topic: @topic}
    @private_commands = {del_topic: @del_topic}
    @message_listeners = [@message_listener]
    @tell._help = "publically passes a message to a user or all followers of a topic whenever they next speak. usage: !tell <user> <message> or !tell #<topic> <message>.\nsee !help topic"
    @topic._help = "subscribes or unsubscribes a user to a topic. !topic add <topic> adds you to topic <topic>, !topic remove <topic> removes you from topic <topic>, !topic add <topic> <user1> <user2> ... adds users to the topic. You are also added to the topic if you aren't following it. !topic list lists all topics. !topic list <topic> lists all followers of a topic.\nsee !help tell"


  tell: (from, tokens, cb) =>
    topic = /^#(.*)$/.exec(_(tokens).first())?[1]
    if (topic)
      @ttell from, topic, _(tokens).tail(), cb
    else
      @utell from, tokens, cb

  utell: (from, tokens, cb) =>
    directed_message from, tokens, cb, @users, (nick, data) =>
      @users.add_tell nick, data

  ttell: (from, topic, tokens, cb) =>
    if _(tokens).isEmpty()
      cb "Message not understood"
    else if _(@users.find('topics', topic)).isEmpty()
      cb "#{topic} is not a known topic"
    else
      followers = _(@users.find('topics', topic)).reject (f) => @users.isAliasOf from, f.key
      if (followers.length > 0)
        _(followers).each (f) => @utell(from, _([f.key]).concat(tokens), -> )
        cb "#{from}: Message Noted and passed on to all followers of #{topic}"
      else
        cb "No one but you is following topic #{topic}"

  message_listener: (from, message) =>
    rec = @users.get(from)
    return if _(message).automated() || !rec
    tells = @users.get_tells(from)
    return if _(tells).isEmpty()
    _(tells).each (item) =>
      @emitter "#{from}: #{item.from} said '#{item.msg}' #{_.date(item.time).fromNow()}"
    @users.clear_tells from

  topic: (from, [command, topic_name, rest...], cb) =>
    topic = /^#(.*)$/.exec(topic_name)?[1] || topic_name
    if !topic and command is "list"
      @list_topics cb
    else if typeof this["topic_#{command}"] is "function" and topic
      this["topic_#{command}"](from, topic, rest, cb)
    else
      cb(@topic._help)

  topic_add: (from, topic, tokens, cb) =>
    {known_nicks, unknown_nicks} = @users.dedupNicks(tokens.concat(from))
    if unknown_nicks.length > 0
      cb "I do not know the following users: #{_(unknown_nicks).sentence()}"
    _(known_nicks).each (n) => @users.add_topic n, topic
    @topic_list from, topic, [], cb

  topic_remove: (from, topic, [nick], cb) =>
    if nick
      cb "you cannot make other people unfollow a topic "
    else
      @users.remove_topic from, topic
      cb "you are now not following the topic #{topic}"

  topic_list: (from, topic, tokens, cb) =>
    nicks = _(@users.find('topics', topic)).pluck('key')
    if nicks and nicks.length > 0
      cb("#{topic} is followed by #{_(nicks).sentence()}")
    else
      cb("#{topic} is not a known topic")

  list_topics: (cb) =>
    topics = @users.indexValues('topics')
    if topics and topics.length > 0
      cb("known topics are #{_(@users.indexValues('topics')).sentence()}")
    else
      cb("no known topics")

  del_topic: (from, [topic, secret_password], cb) =>
    if topic and secret_password is @secret_password
      _(@users.find('topics', topic)).each (u) => @users.remove_topic u.key, topic
      cb "done"

module.exports = Tell

