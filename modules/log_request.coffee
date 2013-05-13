fs = require("fs")
_ = require('../utils')
PEG = require("pegjs")
parser = PEG.buildParser(fs.readFileSync("#{__dirname}/log_request/log_request.pegjs", "ascii"))

class LogRequest
  constructor: ({settings}) ->
    @commands = {logs: @command}
    @command._help = "Display logs for the channel for some point in time. usage: !logs <x days, y hours, z mins ago> or !logs now or !logs q <search terms>"
    @url = "#{settings["baseURL"]}:#{settings["port"]}"

  command: (from, tokens, cb) =>
    cb @parse(tokens)

  parse: (tokens) =>
    return "#{@url}/##{_.now(true)}" if _(tokens).head() is "now"
    return "#{@url}/search?q=#{_(tokens).tail().join("+")}" if _(tokens).head() is "q"
    return @check_time_in_past(tokens) if _(tokens).last() is "ago"
    "usage: !logs <x days, y hours, z mins ago> or !logs now or !logs q <search terms>"

  check_time_in_past: (tokens) =>
    try
      time = parser.parse(_(tokens).join(" "))
      time_hash = _(time).inject((hsh, item) =>
        return if (not hsh) or (item[1] of hsh)
        hsh[item[1]] = item[0]
        hsh
      , {})
      if time_hash
        "#{@url}/##{_.now().subtract(time_hash).date.getTime()}"
      else
       "that makes no sense"
    catch err
      "that makes no sense"

module.exports = LogRequest