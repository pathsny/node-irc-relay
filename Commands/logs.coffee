PEG = require("pegjs")
fs = require("fs")
parser = PEG.buildParser(fs.readFileSync("./logs/log_request.pegjs", "ascii"))

module.exports = {
  name: 'logs',
  help: "Display logs for the channel for some point in time. usage: !logs <x days, y hours, z mins ago> or !logs now or !logs q <search terms>",
  command: (from, tokens, cb) ->
    url = @settings["baseURL"] + ":" + @settings["port"]
    if _(tokens).head() is "now"
      cb url + "/#" + _.now(true)
    else if _(tokens).head() is "q"
      cb url + "/search?q=" + _(tokens).tail().join("+")
    else if _(tokens).last() is "ago"
      try
        time = parser.parse(_(tokens).join(" "))
        time_hash = _(time).inject((hsh, item) ->
          return  if (not hsh) or (item[1] of hsh)
          hsh[item[1]] = item[0]
          hsh
        , {})
        if time_hash
          cb url + "/#" + _.now().subtract(time_hash).date.getTime()
        else
          cb "that makes no sense"
      catch err
        cb "that makes no sense"
    else
      cb "usage: !logs <x days, y hours, z mins ago> or !logs now or !logs q <search terms>"
}