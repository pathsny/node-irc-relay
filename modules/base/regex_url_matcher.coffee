class RegexUrlMatcher
  constructor: (users, settings, @emitter) ->
    @message_listeners = [@message_listener]

  message_listener: (from, msg) =>
      r = _(@regexes).find (r) => r.test(msg)
      @on_match from, r.exec(msg) if r

module.exports = RegexUrlMatcher