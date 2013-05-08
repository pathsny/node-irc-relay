Modules provide various peices of functionality.
Each javascript or coffeescript file in this directory defines a new module.

To create a module, you have to export a constructor which is invoked with a copy of the
user database and the settings.

a module can provide
 1) a map called commands which are commands invoked from the channel.
 2) a map called privateCommands, which are privateCommands invoked via pm.
 3) an array called listeners which get each line printed on the channel and can respond to it.
