# Prints out details about an IMDB url
_ = require('../utils')
RegexUrlMatcher = require("#{__dirname}/base/regex_url_matcher")
param_string = _({v: 2,alt: "jsonc"}).stringify()

class ImdbUrlIdentifier extends RegexUrlMatcher
  regexes: [/http:\/\/www\.imdb\.com\/title\/(.*)\//]

  on_match: (from, match) =>
    url = "http://www.imdbapi.com/?i=#{match[1]}"
    _.request {uri: url}, (error, response, body) =>
      if not error and response.statusCode is 200
        {Title, Year, Plot} = JSON.parse(body)
        @emitter "ah #{from} is talking about #{Title} (#{Year}) which is about #{Plot}"

module.exports = ImdbUrlIdentifier
