class Token
  constructor: ({@users, settings}) ->
    @private_commands = {token: @private_command}
    @private_command._help = "token : gives you a token for the web history at #{settings['baseURL']}:#{settings['port']}"

  private_command: (from, tokens, cb) =>
    token = @users.createToken(from)
    cb token if token

module.exports = Token