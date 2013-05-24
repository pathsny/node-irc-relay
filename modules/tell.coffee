directed_message = require "#{__dirname}/base/directed_message"
_ = require('../utils')

class Tell
  constructor: ({@users, @emitter}) ->
    @users.defineArrayProperty 'tell'
    @users.defineSetProperty 'topic'
    @users.addIndex "topics", (k, v) -> v.topics || []

    @commands = {tell: @tell, topic: @topic}
    @message_listeners = [@message_listener]
    @tell._help = "publically passes a message to a user or all followers of a topic whenever they next speak. usage: !tell <user> <message> or !tell #<topic> <message>.\nsee !help topic"
    @topic._help = "subscribes or unsubscribes a user to a topic. !topic add <topic> adds you to topic <topic>, !topic remove <topic> removes you from topic <topic>, !topic add <topic> <user> adds user to the topic. !topic list lists all topics. !topic list <topic> lists all followers of a topic.\nsee !help tell."


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
      followers = @users.find('topics', topic)
      _(followers).each (f) => @utell(from, _([f.key]).concat(tokens), -> )
      cb "#{from}: Message Noted and passed on to all followers of #{topic}"

  message_listener: (from, message) =>
    rec = @users.get(from)
    return if _(message).automated() || !rec
    tells = @users.get_tells(from)
    return if _(tells).isEmpty()
    _(tells).each (item) =>
      @emitter "#{from}: #{item.from} said '#{item.msg}' #{_.date(item.time).fromNow()}"
    @users.clear_tells from

  topic: (from, tokens, cb) =>
    command = _(tokens).first()
    topic = /^#(.*)$/.exec(_(tokens).second())?[1] || _(tokens).second()
    if !topic and command is "list"
      @list_topics cb
    else if typeof this["topic_#{command}"] is "function" and topic
      this["topic_#{command}"](from, topic, _(tokens).tail(2), cb)
    else
      cb(@topic._help)

  topic_add: (from, topic, tokens, cb) =>
    nick = _(tokens).first()
    if nick
      if @users.get(nick)
        @users.add_topic nick, topic
        cb "#{nick} is now following the topic #{topic}"
      else
        cb "I do not know a user called #{nick}."
    else
      @users.add_topic from, topic
      cb "you are now following the topic #{topic}"

  topic_remove: (from, topic, tokens, cb) =>
    nick = _(tokens).first()
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

module.exports = Tell

