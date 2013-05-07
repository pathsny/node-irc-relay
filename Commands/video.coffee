module.exports = {
  name: 'video',
  help: "Video chat with other people in the channel",
  command: (from, tokens, cb) ->
    cb @settings["baseURL"] + ":" + @settings["port"] + "/video"
}


