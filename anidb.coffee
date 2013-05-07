_ = require("underscore")
require "./utils"
module.exports = getInfo: (aid, cb) ->
  url = "http://api.anidb.net:9001/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=" + aid
  _.requestXmlAsJson
    uri: url
    cache: aid
  , (err, data) ->
    unless err
      unless data.description
        data.splitDescription = "no data provided"
        cb data
        return
      desc = data.description.split("\n")
      data.splitDescription = _(desc).chain().invoke_("inSlicesOf", 400).flatten().join("\n").value()
      cb data

