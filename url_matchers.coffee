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
  ytube:
    regexes: [/https?:\/\/(?:www\.)?youtube\.com\/watch\?(?:[^\s\t]*&?)v=([A-Za-z0-9_-]+)(?:.*?)/, /https?:\/\/youtu\.be\/([A-Za-z0-9_-]+)/]
    responder: (from, message, match, respond) ->
      url = "http://gdata.youtube.com/feeds/api/videos/" + match[1] + "?" + _(
        v: 2
        alt: "jsonc"
      ).stringify()
      _.request
        uri: url
      , (error, response, body) ->
        if not error and response.statusCode is 200
          res = JSON.parse(body).data
          
          # Date() is too hard, let's go shopping
          hour = ~~(res.duration / 3600)
          min = ~~((res.duration - hour * 3600) / 60)
          sec = ~~(res.duration - hour * 3600 - min * 60)
          time_string = ""
          time_string += hour + " hours, "  unless hour is "0"
          time_string += min + " min, "  unless min is "0"
          time_string += "and "  if hour isnt "0" or min isnt "0"
          time_string += sec + " secs"
          respond "ah " + from + " is talking about " + _(res.category).articleize() + " video of length " + time_string + " called \"" + res.title + "\". The Tags are " + _(res.tags).sentence() + "."


  anidb:
    regexes: [/http:\/\/anidb\.net\/perl-bin\/animedb.pl\?(?:.*)aid=(\d+)(?:.*)/]
    responder: (from, message, match, respond) ->
      anidb.getInfo match[1], (data) ->
        titles = data.titles.title
        english_title_node = _(titles).find(_titleMatchers[0]) or _(titles).find(_titleMatchers[1]) or _(titles).find(_titleMatchers[2])
        msg = _(titles).find((t) ->
          t.type is "main"
        )["#"]
        msg += " (" + english_title_node["#"] + ")"  if english_title_node
        respond "That anidb link is " + msg
        respond data.splitDescription


  imdb:
    regexes: [/http:\/\/www\.imdb\.com\/title\/(.*)\//]
    responder: (from, message, match, respond) ->
      url = "http://www.imdbapi.com/?i=" + match[1]
      _.request
        uri: url
      , (error, response, body) ->
        if not error and response.statusCode is 200
          res = JSON.parse(body)
          respond "ah " + from + " is talking about " + res["Title"] + "(" + res["Year"] + ") which is about " + res["Plot"]

