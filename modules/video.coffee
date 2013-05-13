class Video
  constructor: ({settings}) ->
    command = (from, tokens, cb) ->
      cb "#{settings["baseURL"]}:#{settings["port"]}/video"
    command._help = "Video chat with other people in the channel"
    @commands = {video: command}

module.exports = Video


