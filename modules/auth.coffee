uuid = require("node-uuid")
_ = require "../utils"
eco = require('eco')
fs = require("fs")

class Auth
  constructor: ({@users, settings: {baseURL, port, @nick}}) ->
    @users.defineScalarProperty 'token'
    @users.addIndex "token", (k, v) -> if v.token then [v.token] else []
    @private_commands = {token: @private_command}
    @private_command._help = "token : gives you a token for the web history at #{baseURL}:#{port}"
    @web_extensions = {'medium': @auth_user}

  private_command: (from, tokens, cb) =>
    return if @users.get(from)?.status isnt "online"
    token = uuid()
    @users.set_token from, token
    cb token

  get_user: (token) ->
    return unless token
    @users.find("token", token)[0]

  auth_user: (app) =>
    login = fs.readFileSync("#{__dirname}/auth/view.eco", "utf8")
    app.use (req, res, next) =>
      if user = @get_user(req.cookies["mtoken"])
        req.session = {nick: user.key}
        next()
        return
      else if user = @get_user(req.body?.mtoken)
        res.cookie('mtoken', req.body.mtoken, { maxAge: 3153600000})
        res.redirect(req.body.return_url or '/')
      else
        res.send 401, eco.render(login, {
          title: 'logs',
          return_url: req.body.return_url or req.url,
          nick: @nick
        })
module.exports = Auth