module.exports = {
  name: 'help',
  command: (from, tokens, cb) ->
    Commands = @constructor.prototype
    if _(tokens).isEmpty()
      cb "I know " + _(Commands).chain().keys().difference(["listeners", "private", "commands", "help"]).map((command) ->
        "!" + command
      ).sentence().value()
      cb "Type !help <command> to know more about any command"
    else
      command = Commands[_(tokens).chain().head().firstMatchIfExists(/!(.*)/).value()]
      helpCommand = (if command then (command["_help"] or "I have no help on this command") else "No Such Command")
      cb (if (typeof helpCommand is "function") then helpCommand.call() else helpCommand)
}

