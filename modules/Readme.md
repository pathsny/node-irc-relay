# Modules #

Modules provide various pieces of functionality.

## Creating ##

To create a module, you have to create a new file.
Each javascript or coffeescript file in this directory defines a new module.
every module should export a constructor.
your constructor will get called with

* a reference to the user database which you can use to store and retrieve data

* the settings so you can retrieve specific settings for your plugin

* an emitter which you can use to emit text onto the channel

## Functionality ##
	Any module can provide any combination of the following types of functionality.

1. any number of commands executed by typing *!&lt;command_name&gt; &lt;arguments&gt;* on the channel.
2. any number of private commands executed by pming the bot.
3. any number of listeners that automatically act on seeing some text.
4. proactively put text in the channel (for example in response to some external stimulus)

A module is just a discrete chunk of functionality and does not need to be exclusively one
of the above types but any combination that makes sense as a whole.

### Commands ###

to expose commands your module must expose a property called *commands* which is a mapping from
the command_name to functions that are invoked when the command is called.

* the command gets these parameters
	1. receives the nick of the person who invoked it.
	2. the remaining text on that line.
	3. a function that can be invoked to respond to the command.
* if the command function has a property called *_help*, it is automatically displayed when someone
types *!help &lt;command_name&gt;*
* for examples look at the modules **google** or **nicks**

### Private Commands ###

TBD

### Message Listeners ###

* message\_listeners get a copy of every message and action and can react to them if necessary. When invoked a
message\_listener receives
	1. the nick of the person who sent the message
	2. the remaining text on that line
* the messages_listener does not receive messages emitted by the bot.
* for examples look at the modules **imdb\_url\_identifier** or **tell**