express = require('express')

ejs = require("ejs")
fs = require("fs")
_ = require("underscore")
require "../utils"
exec = require("child_process").exec
url = require("url")
qs = require("querystring")
socket_io = require("socket.io")
Server = exports.Server = (users, nick, port, textEmittor, sendChat) ->
  views = _(["index", "login", "search", "video"]).inject((views, page) ->
    _({}).chain().extend(views).tap((views) ->
      views[page] = fs.readFileSync(__dirname + "/views/" + page + ".ejs", "utf8")
    ).value()
  , {})
  auth = (req, res, next) ->
    if users.validToken(req.cookies["mtoken"])
      next()
      return
    else if users.validToken(req.body and req.body["mtoken"])
      console.log("you have a valid token and it is ", req.body["mtoken"])
      cookieString = ejs.render("mtoken=<%=mtoken%>; Max-Age=3153600000",
        locals:
          mtoken: req.body["mtoken"]
      )
      res.writeHead 302,
        Location: (req.body["ReturnUrl"] or "/")
        "Set-Cookie": cookieString

      res.end()
      return
    res.end ejs.render(views["login"],
      locals:
        title: "MISAKA logs"
        ReturnUrl: req.url
        nick: nick
    )

  search = (req, res) ->
    parsedUrl = qs.parse(url.parse(req.url).query)
    res.writeHead 200,
      "Content-Type": "text/html; charset=utf-8;"

    search = parsedUrl["q"]
    render = (res, search, results) ->
      res.end ejs.render(views["search"],
        locals:
          title: "MISAKA logs"
          search: search
          results: results
      )

    if search
      cmd = "egrep -h -m 10 '\\b(" + _(search.split(" ")).join("|") + ")\\b' data/irclogs/*.log"
      exec cmd, (error, stdout, stderr) ->
        results = (if stdout is "" then [] else _(stdout.split("\n")).map((l) ->
          t = l.indexOf(",")
          timestamp = Number(l.slice(1, t))
          timestamp: timestamp
          date: _.date(timestamp).format("dddd, MMMM Do YYYY, hh:mm:ss")
          msg: l.slice(t + 2, -2)
        ))
        render res, search, results

    else
      render res, "", []

  app = express()
  app.use(express.compress())
  app.use(express.bodyParser())
  app.use(express.static("#{__dirname}/public"))
  app.use(express.static("#{__dirname}/../data/irclogs"))
  app.use(express.cookieParser())
  app.use(auth)
  app.get "/", (req, res, next) ->
    res.type("html")
    res.send ejs.render(views["index"], locals: title: "MISAKA logs")
  app.get "/search", search
  app.get "/video", (req, res) ->
    aliases = users.aliases(users.validToken(req.cookies["mtoken"]).key)
    if _(aliases).any((item) -> item.val.status is "online")
      res.end ejs.render(views["video"],
        locals:
          nick: users.validToken(req.cookies["mtoken"]).key
        )
    else
      res.end ejs.render("You must be in the channel to participate")

  console.log "starting webserver on port #{port}"
  app.listen Number(port)

  # io = socket_io.listen(app)
  # io.configure ->
  #   io.enable "browser client minification"
  #   io.enable "browser client etag"
  #   io.enable "browser client gzip"
  #   io.set "log level", 1
  #
  # peers = {}
  # id = 0
  # getNick = (socket) ->
  #   cookie_string = socket.handshake.headers.cookie
  #   parsed_cookies = connect.utils.parseCookie(cookie_string)
  #   nick = users.validToken(parsed_cookies["mtoken"]).key
  #   id++
  #   nick + " " + id
  #
  # io.sockets.on "connection", (socket) ->
  #   nick = getNick(socket)
  #   socket.broadcast.emit "user connected", nick
  #   socket.emit "existing users", _(peers).keys()
  #   peers[nick] = socket
  #   socket.on "disconnect", ->
  #     delete peers[nick]
  #
  #     socket.broadcast.emit "user disconnected", nick
  #
  #   socket.on "chat_message", (m) ->
  #     sendChat "<" + nick.split(" ")[0] + "|Video>: ", m
  #
  #   socket.on "signalling message", (data) ->
  #     otherSocket = peers[data.user]
  #     unless otherSocket
  #       console.log "cannot find socket of user ", data.user
  #       return
  #     otherSocket.emit "signalling message",
  #       user: nick
  #       data: data.data
  #
  #
  #
  # textEmittor.on "text", _(io.sockets.emit).bind(io.sockets, "text")
