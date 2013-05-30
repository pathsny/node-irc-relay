fs = require("fs")

extract_array_prop = (list, prop) ->
  _(list).chain().
  pluck(prop).
  compact().
  flatten().
  value()

class Modules
  constructor: (users, settings, app) ->
    @options = {users: users, settings: settings, emitter: @emitter}
    instances = _(fs.readdirSync("#{__dirname}/modules")).
      chain().
      map((f) => f.match(/^(.*)\.(?:js|coffee)$/)?[1]).
      compact().
      filter(@module_filter(settings['load_modules'])).
      map(@create_module).
      compact().
      value();
    @_commands = _({}).extend(_(instances).pluck('commands')...)
    @_private_commands = _({}).extend(_(instances).pluck('private_commands')...)
    @_message_listeners = extract_array_prop instances, 'message_listeners'
    @_private_listeners = extract_array_prop instances, 'private_listeners'
    @web_extensions = @extract_web_extensions instances
    _(['high', 'medium', 'low']).each (priority) =>
      _(@web_extensions[priority]).each (ext_fn) -> ext_fn(app)

  initialize: (@bot) =>
    channel = @options['settings']['channel']
    @bot.on "message#{channel}", @on_channel_msg
    @bot.on 'action', (from, to, msg) => @on_channel_msg(from, msg) if to is channel

    @bot.on 'pm', (from, msg) =>
      _(@_private_listeners).each (l) -> l(from, msg)
      [command, rest...] = _(msg.split(" ")).compact()
      if command and typeof (@_private_commands[command]) is "function"
        @_private_commands[command] from, rest, (r) => @bot.say from, r

  on_channel_msg: (from, msg) =>
    _(@_message_listeners).each (l) -> l(from, msg)
    [first, rest...] = _(msg.split(" ")).compact()
    command = /^!(.*)/.exec(first)?[1]
    if command and typeof (@_commands[command]) is "function"
      @_commands[command] from, rest, @bot.channel_say

  emitter: (args...) => @bot.channel_say(args...)

  module_filter: ({restriction, modules}) ->
    return (-> true) if restriction is 'none'
    return ((f) -> _(modules).contains(f)) if restriction is 'whitelist'
    return ((f) -> !_(modules).contains(f)) if restriction is 'blacklist'
    throw "unrecognised setting for load_modules"

  extract_web_extensions: (instances) =>
    _(instances).
    chain().
    pluck('web_extensions').
    compact().
    reduce((ext, web_i) ->
      _(['high', 'medium', 'low']).each (p) ->
        ext[p].push(web_i[p]) if web_i[p]
      ext
    , {'high': [], 'medium': [], 'low': []}).value()

  create_module: (file) =>
    try
      ModuleKlass = require "./modules/#{file}"
      new ModuleKlass(@options)
    catch error
      console.log("could not load module #{file} because #{error}")
      null

module.exports = Modules