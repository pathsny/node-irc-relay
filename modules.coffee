fs = require("fs")
modules = (require("./modules/#{f}") for f in fs.readdirSync("./modules") when f.match /\.(?:js|coffee)$/)

class Modules
  constructor: (users, settings) ->
    commandSets = modules.map (Module_x) -> (new Module_x(users, settings)).commands
    @_commands = _({}).extend(commandSets...)

  Object.defineProperties @prototype,
      commands:
        get: -> @_commands

module.exports = Modules