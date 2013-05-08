class RegexUrlMatcher
  constructor: (users, settings, @emittor) ->
    @listeners = [@listener]

  listener: (from, msg) =>
      r = _(@regexes).find (r) -> r.test(msg)
      @on_match from, r.exec(msg) if r

module.exports = RegexUrlMatcher