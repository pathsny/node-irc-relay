_ = require("underscore")
require "./utils"
param_string = _({
  request: 'anime',
  client: 'misakatron',
  clientver: '1',
  protover: '1'
}).stringify()

module.exports = getInfo: (aid, cb) ->
  url = "http://api.anidb.net:9001/httpapi?#{param_string}&aid=#{aid}"
  _.requestXmlAsJson {uri: url, cache: aid}, (err, {anime}) ->
    return if err
    unless anime.description
      anime.splitDescription = "no description provided"
      cb anime
      return
    desc = _(anime.description).first().split("\n")
    anime.splitDescription = _(desc).chain().invoke_("inSlicesOf", 400).flatten().join("\n").value()
    cb anime

