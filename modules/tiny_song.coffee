_ = require('../utils')

class TinySong
  constructor: ({settings}) ->
    @params = _({format: "json", key: settings["tinysong_key"]}).stringify()
    @commands = {m: @command}
    @command._help = "searches tinysong and provides a url to grooveshark to listen to the song"

  url: (query) =>
    "http://tinysong.com/b/#{encodeURIComponent(query)}?#{@params}"

  parse: (query, body) =>
    responseJson = JSON.parse(body)
    if responseJson.Url?
      "Listen to #{responseJson.ArtistName} - #{responseJson.SongName} at #{responseJson.Url}"
    else
      "No song found for: #{query}"

  command: (from, tokens, cb) =>
    query = tokens.join(" ").replace(/^\s+|\s+$/g, "")
    _.request {uri: @url(query)}, (error, response, body) =>
      if error or response.statusCode isnt 200
        cb("Tiny Song Error")
      else
        cb @parse(query, body)

module.exports = TinySong