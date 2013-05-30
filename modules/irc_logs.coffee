fs = require("fs")
_ = require('../utils')
PEG = require("pegjs")
Logger = require('./irc_logs/logger')
express = require('express')
ejs = require('ejs')
parser = PEG.buildParser(fs.readFileSync("#{__dirname}/log_request/log_request.pegjs", "ascii"))

class IrcLogs
  constructor: (settings: {baseURL, port}) ->
    @commands = {logs: @command}
    @command._help = "Display logs for the channel for some point in time. usage: !logs <x days, y hours, z mins ago> or !logs now or !logs q <search terms>"
    @url = "#{baseURL}:#{port}"
    @text_listeners = [new Logger().log]
    @web_extensions = {'low': @display_logs}

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

  display_logs: (app) =>
    display_logs = fs.readFileSync("#{__dirname}/irc_logs/display_logs.ejs", "utf8")
    app.use('/logs', express.static("#{__dirname}/../data/irclogs"))
    app.use('/irc_logs', express.static("#{__dirname}/irc_logs/static"))
    app.get "/", (req, res) =>
      res.send ejs.render(display_logs, locals: title: "MISAKA logs")


module.exports = IrcLogs