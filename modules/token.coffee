class Token
  constructor: (@users, settings, emitter) ->
    @private_commands = {token: @private_command}

  private_command: (from, tokens, cb) =>
    token = @users.createToken(from)
    cb token if token

module.exports = Token