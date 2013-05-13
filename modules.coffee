fs = require("fs")
modules = (require("./modules/#{f}") for f in fs.readdirSync("./modules") when f.match /\.(?:js|coffee)$/)

class Modules
  constructor: (users, settings, emitter) ->
    options = {users: users, settings: settings, emitter: emitter}
    instances = modules.map (Module_x) -> new Module_x(options)
    @_commands = _({}).extend(_(instances).pluck('commands')...)
    @_private_commands = _({}).extend(_(instances).pluck('private_commands')...)
    @_message_listeners = _(instances).chain().
      pluck('message_listeners').
      compact().
      flatten().
      value()

  Object.defineProperties @prototype,
      commands:
        get: -> @_commands
      message_listeners:
        get: -> @_message_listeners
      private_commands:
        get: -> @_private_commands

module.exports = Modules