_ = require("underscore")
gtalk = require("./gtalk").gtalk
require "./utils"

class Commands
  constructor: (@users, @settings) ->

module.exports = Commands

Commands::help = (from, tokens, cb) ->
  cb "token : gives you a token for the web history at www.got-rice.asia:8008"
  cb "list : lists all messages left for you"
  cb "del <x> : deletes the xth message"
  cb "email <emailaddress> : sets an alert email address. email clear : clears the alert email address"
  cb "gtalk <gtalkid> : sets a gtalk id. gtalk clear : clears the gtalk id"

Commands::token = (from, tokens, cb) ->
  token = @users.createToken(from)
  cb token  if token

Commands::list = (from, tokens, cb) ->
  return  unless @users.get(from)
  msgs = @users.getMsgs(from)
  if msgs.length > 0
    _(msgs).chain().zipWithIndex().forEach (item) ->
      msg = item[0]
      reply = (item[1] + 1) + ". " + msg.from + " said '" + msg.msg + "'"
      reply += " " + _.date(msg.time).fromNow()  if msg.time
      cb reply

  else
    cb "There are no messages for you"

Commands::del = (from, tokens, cb) ->
  return  unless @users.get(from)
  first = _(tokens).head()
  if first and /^\d+$/.test(first)
    number = Number(first)
    if @users.deleteMsg(from, number - 1)
      cb "message number " + number + " has been deleted"
    else
      cb "there is no message number " + number
  else
    cb "delete requires a message number to delete"

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

