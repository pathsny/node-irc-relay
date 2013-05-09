fs = require("fs")
modules = (require("./modules/#{f}") for f in fs.readdirSync("./modules") when f.match /\.(?:js|coffee)$/)

class Modules
  constructor: (users, settings, emitter) ->
    instances = modules.map (Module_x) -> new Module_x(users, settings, emitter)
    @_commands = _({}).extend(_(instances).pluck('commands')...)
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

module.exports = Modules