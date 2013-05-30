exec = require("child_process").exec
fs = require('fs')
_ = require("../utils")
eco = require "eco"

class LogsSearch
  constructor: (settings: {baseURL, port}) ->
    @commands = {qlogs: @command}
    @command._help = "Searches through channel logs. usage: !qlogs <search terms>"
    @url = "#{baseURL}:#{port}"
    @web_extensions = {'low': @search_logs}

  command: (from, tokens, cb) =>
    cb "#{@url}/search?q=#{tokens.join('+')}"

  search_logs: (app) =>
    search_page = fs.readFileSync("#{__dirname}/logs_search/view.eco", "utf8")
    app.get '/search', (req, res) =>
      locals = {title: 'MISAKA logs', search: req.query.q, results: []}
      if locals.search and locals.search != ''
        tokens = locals.search.split(' ')
        cmd = "egrep -h -m 10 '\\b(#{tokens.join('|')})\\b' data/irclogs/*.log"
        exec cmd, (e, stdout, stderr) =>
          locals.results = _(stdout.split("\n")).chain().map((l) =>
            return null if l == ""
            t = l.indexOf(",")
            timestamp = Number(l.slice(1, t))
            {
              timestamp: timestamp,
              date: _.date(timestamp).format("dddd, MMMM Do YYYY, hh:mm:ss"),
              msg: l.slice(t+2, -2)
            }).compact().value()
          res.send eco.render(search_page, locals)
      else
        res.send eco.render(search_page, locals)

module.exports = LogsSearch