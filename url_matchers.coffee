_ = require("underscore")
require "./utils"
anidb = require("./anidb")
_titleMatchers = [(t) ->
  t["xml:lang"] is "en" and t.type is "official"
, (t) ->
  t["xml:lang"] is "en" and t.type is "synonym"
, (t) ->
  t["xml:lang"] is "x-jat" and t.type is "synonym"
]
exports.matchers =
  anidb:
    regexes: [/http:\/\/anidb\.net\/perl-bin\/animedb.pl\?(?:.*)aid=(\d+)(?:.*)/]
    responder: (from, message, match, respond) ->
      anidb.getInfo match[1], (data) ->
        # console.log(data)
        # console.log(data.titles)
        # console.log(data.titles[0].title)
        titles = data.titles[0].title
        english_title_node = _(titles).find(_titleMatchers[0]) or _(titles).find(_titleMatchers[1]) or _(titles).find(_titleMatchers[2])
        msg = _(titles).find((t) ->
          t.type is "main"
        )["#"]
        msg += " (" + english_title_node["#"] + ")"  if english_title_node
        respond "That anidb link is " + msg
        respond data.splitDescription

