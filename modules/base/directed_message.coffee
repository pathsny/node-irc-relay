_ = require "../../utils"

module.exports = (from, tokens, cb, users, success) ->
  to = _(tokens).head()
  msg = _(tokens).tail().join(" ")
  unless to and msg
    cb "Message not understood"
  else unless users.get(to)
    cb to + " is not known"
  else
    success to, {from: from, msg: msg, time: Date.now()}
    cb "#{from}: Message Noted"