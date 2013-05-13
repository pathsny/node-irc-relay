_ = require('../utils')

# this class works via magic using the fact that the this operator is
# dynamically scoped

command_or_string = (string) ->
  match = /!(.*)/.exec(string)
  if match then match[1] else string

help_string = (commandFn) ->
    return "No Such Command" unless commandFn
    fn_or_string = commandFn["_help"] or "I have no help on this command"
    if (typeof fn_or_string is "function") then fn_or_string() else fn_or_string

class Help
  constructor: ->
    @commands = {help: @command}
    @private_commands = {help: @private_command}

  private_command: (from, tokens, cb) ->
    _(this).chain().
      values().
      each (pc) -> cb(pc._help)

  command: (from, tokens, cb) ->
    if _(tokens).isEmpty()
      names = _(this).chain().
        keys().
        difference(["commands", "help"]).
        map((c) -> "!#{c}").
        sentence().
        value()
      cb "I know #{names}";
      cb "Type !help <command> to know more about any command"
    else
      command = this[command_or_string(tokens[0])]
      cb help_string(command)

module.exports = Help