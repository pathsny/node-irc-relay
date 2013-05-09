# Prints out details about an youtube url
_ = require('../utils')
RegexUrlMatcher = require("#{__dirname}/base/regex_url_matcher")
param_string = _({v: 2,alt: "jsonc"}).stringify()

class ImdbUrlMatcher extends RegexUrlMatcher
  regexes: [
    /https?:\/\/(?:www\.)?youtube\.com\/watch\?(?:[^\s\t]*&?)v=([A-Za-z0-9_-]+)(?:.*?)/,
    /https?:\/\/youtu\.be\/([A-Za-z0-9_-]+)/
  ]

  url: (video_id) =>
    "http://gdata.youtube.com/feeds/api/videos/#{video_id}?#{param_string}"

  on_match: (from, match) =>
    _.request {uri: @url(match[1])}, (error, response, body) =>
      return if error or response.statusCode isnt 200
      @emitter "ah #{from} is talking about #{@describe(JSON.parse(body).data)}"

  duration_string: (duration) =>
    # Date() is too hard, let's go shopping
    hour = ~~(duration / 3600)
    min = ~~((duration - hour * 3600) / 60)
    sec = ~~(duration - hour * 3600 - min * 60)
    time_string = ""
    time_string += "#{hour} hours, " unless hour is 0
    time_string += "#{min} min, " unless min is 0
    time_string += "and " if hour isnt 0 or min isnt 0
    time_string += "#{sec} secs"
    time_string

  describe: ({duration, title, category, tags}) =>
    "#{_(category).articleize()} video of length #{@duration_string(duration)} called #{title}. The category is #{category}."

module.exports = ImdbUrlMatcher
