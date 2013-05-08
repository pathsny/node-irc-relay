class Video
  constructor: (users, settings) ->
    fn = (from, tokens, cb) ->
      cb "#{settings["baseURL"]}:#{settings["port"]}/video"
    fn._help = "Video chat with other people in the channel"
    @commands = {video: fn}

module.exports = Video


