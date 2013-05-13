_ = require("underscore")
gtalk = require("./gtalk").gtalk
require "./utils"

class Commands
  constructor: (@users, @settings) ->

module.exports = Commands

Commands::help = (from, tokens, cb) ->
  cb "email <emailaddress> : sets an alert email address. email clear : clears the alert email address"
  cb "gtalk <gtalkid> : sets a gtalk id. gtalk clear : clears the gtalk id"


contact_points =
  phone:
    property: "PhoneNumber"
    regex: /^\d+$/
    help: "number <actual number only digits> to set your number. number clear it"

  email:
    property: "EmailAddress"
    regex: /^[^@]+@[^@]+$/
    help: "email <email address> to set your email address. email clear to clear it"

  gtalk:
    property: "GtalkId"
    regex: /^[^@]+@[^@]+$/
    help: "gtalk <gtalkid> to set your gtalk id. gtalk clear to clear it"
    custom_fn: _(gtalk.addAccount).bind(gtalk)

_(contact_points).each (params, command) ->
  Commands::[command] = (from, tokens, cb) ->
    return  unless @users.get(from)
    first = _(tokens).head()
    if first and params.regex.test(first)
      console.log('got a request for ', params.property, from, tokens, cb)
      unless params.custom_fn
        @users["set_" + params.property] from, first
        cb "your " + params.property + " has been recorded as " + first
      else
        params.custom_fn from, first, cb
    else if first and first is "clear"
      @users["clear_" + params.property] from
      cb "your " + params.property + " has been cleared"
    else
      cb params.help

