fs = require("fs")

class Modules
  constructor: (users, settings, emitter) ->
    @options = {users: users, settings: settings, emitter: emitter}
    instances = _(fs.readdirSync("./modules")).
      chain().
      map((f) => f.match(/^(.*)\.(?:js|coffee)$/)?[1]).
      compact().
      filter(@module_filter(settings['load_modules'])).
      map(@create_module).
      compact().
      value();
    @_commands = _({}).extend(_(instances).pluck('commands')...)
    @_private_commands = _({}).extend(_(instances).pluck('private_commands')...)
    @_message_listeners = _(instances).chain().
      pluck('message_listeners').
      compact().
      flatten().
      value()

  module_filter: ({restriction, modules}) ->
    return (-> true) if restriction is 'none'
    return ((f) -> _(modules).contains(f)) if restriction is 'whitelist'
    return ((f) -> !_(modules).contains(f)) if restriction is 'blacklist'
    throw "unrecognised setting for load_modules"

  create_module: (file) =>
    try
      ModuleKlass = require "./modules/#{file}"
      new ModuleKlass(@options)
    catch error
      console.log("could not load module #{file} because #{error}")
      null


  Object.defineProperties @prototype,
      commands:
        get: -> @_commands
      message_listeners:
        get: -> @_message_listeners
      private_commands:
        get: -> @_private_commands

module.exports = Modules