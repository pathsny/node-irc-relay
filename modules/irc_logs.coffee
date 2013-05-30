# takes care of logging all data and allows you to request logs for any point in time and view it on the web
fs = require("fs")
_ = require('../utils')
PEG = require("pegjs")
Logger = require('./irc_logs/logger')
express = require('express')
eco = require('eco')
parser = PEG.buildParser(fs.readFileSync("#{__dirname}/irc_logs/log_request.pegjs", "ascii"))

class IrcLogs
  constructor: (settings: {baseURL, port}) ->
    @commands = {logs: @command}
    @command._help = "Display logs for the channel for some point in time. usage: !logs <x days, y hours, z mins ago> or !logs now"
    @url = "#{baseURL}:#{port}"
    @text_listeners = [new Logger().log]
    @web_extensions = {'low': @display_logs}

  command: (from, tokens, cb) =>
    cb @parse(tokens)

  parse: (tokens) =>
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
       "usage: !logs <x days, y hours, z mins ago> or !logs now"
    catch err
      "usage: !logs <x days, y hours, z mins ago> or !logs now"

  display_logs: (app) =>
    display_logs = fs.readFileSync("#{__dirname}/irc_logs/view.eco", "utf8")
    app.use('/logs', express.static("#{__dirname}/../data/irclogs"))
    app.use('/irc_logs', express.static("#{__dirname}/irc_logs/static"))
    app.get "/", (req, res) =>
      res.send eco.render(display_logs, {title: "MISAKA logs"})


module.exports = IrcLogs