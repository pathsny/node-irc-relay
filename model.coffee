userdb = require("dirty")("./data/user.db")
uuid = require("node-uuid")
_ = require("underscore")
require "./utils"
inflection = require 'inflection'
userdb.addIndex "nickId", (k, v) ->
  v.nickId

userdb.addIndex "token", (k, v) ->
  v.token

userdb.addIndex "twitter_id", (k, v) ->
  v.twitter_id

userdb.listeners = [
  type: "names"
  listener: (channel, given_nicks) ->
    nicks = _(given_nicks).chain().keys().without("").map((nick) ->
      match = /[~%](.*)/.exec(nick)
      (if match then match[1] else nick)
    ).value()
    userdb.addNicks nicks
    userdb.forEach (nick, doc) ->
      userdb.offline nick  unless _(nicks).include(nick)
      nicks = _(nicks).without(nick)

,
  type: "join"
  listener: (channel, nick) ->
    userdb.addNick nick
,
  type: "part"
  listener: (channel, nick) ->
    userdb.offline nick
,
  type: "kick"
  listener: (channel, nick) ->
    userdb.offline nick
,
  type: "quit"
  listener: (nick, message, channels) ->
    userdb.offline nick, message
,
  type: "nick"
  listener: (oldnick, newnick) ->
    userdb.offline oldnick
    userdb.addNick newnick
    userdb.link(oldnick, newnick) or userdb.link(newnick, oldnick)
,
  type: "message"
  listener: (from, to, message) ->
    userdb.lastMessage from, message  if /^#/.test(to) and not _(message).automated()
]
userdb.link = (nick, nickgroup) ->
  rec = userdb.get(nick)
  recgroup = userdb.get(nickgroup)
  return false  unless rec and recgroup and userdb.aliases(nick).length is 1
  rec.nickId = recgroup.nickId
  userdb.set nick, rec
  true

userdb.unlink = (nick, nickgroup) ->
  rec = userdb.get(nick)
  recgroup = userdb.get(nickgroup)
  return false  unless rec and recgroup and rec.nickId is recgroup.nickId
  rec.nickId = uuid()
  userdb.set nick, rec
  true

userdb.linkAll = (nickgroup1, nickgroup2) ->
  rec1 = userdb.get(nickgroup1)
  rec2 = userdb.get(nickgroup2)
  return false  unless rec1 and rec2
  _(userdb.find("nickId", rec1.nickId)).each (item) ->
    rec = item.val
    rec.nickId = rec2.nickId
    userdb.set item.key, rec

  true

userdb.addNick = (nick) ->
  rec = userdb.get(nick)
  if rec
    return rec  if rec.status is "online"
    rec.status = "online"
    rec.lastSeen = new Date().getTime()
    userdb.set nick, rec
    return rec
  rec =
    lastSeen: new Date().getTime()
    timeSpent: 0
    nickId: uuid()
    status: "online"

  userdb.set nick, rec
  rec

userdb.online = (nick) ->
  rec = userdb.get(nick)
  return  if rec.status is "online"
  rec.status = "online"
  rec.lastSeen = new Date().getTime()
  userdb.set nick, rec

userdb.lastMessage = (nick, message) ->
  rec = userdb.get(nick)
  rec.status = "online"
  time = new Date().getTime()
  rec.timeSpent = time - rec.lastSeen
  rec.lastSeen = time
  rec.lastMessage =
    msg: message
    time: time
  userdb.set nick, rec

userdb.offline = (nick, quitMsg) ->
  rec = userdb.get(nick)
  unless rec
    console.log "error"
    console.log nick
    console.log rec
    return
  return  if rec.status is "offline"
  rec.status = "offline"
  rec.quitMsg = quitMsg
  time = new Date().getTime()
  rec.timeSpent = time - rec.lastSeen
  rec.lastSeen = time
  userdb.set nick, rec

userdb.addNicks = (nicks) ->
  _(nicks).each (nick) ->
    userdb.addNick nick


userdb.aliases = (nick) ->
  rec = userdb.get(nick)
  userdb.find "nickId", rec.nickId

userdb.aliasedNicks = (nick) ->
  return `undefined`  unless userdb.get(nick)
  _(userdb.aliases(nick)).pluck "key"

userdb.createToken = (nick) ->
  rec = userdb.get(nick)
  return  if rec.status isnt "online"
  rec["token"] = uuid()
  userdb.set nick, rec
  rec["token"]

userdb.validToken = (token) ->
  return  unless token
  _(userdb.find("token", token)).first()

userdb.clearProperty = (prop_name, nick) ->
  _(@aliases(nick)).
  chain().
  filter((item) -> _(item.val).has(prop_name)).
  each (item) ->
    delete item.val[prop_name]
    userdb.set item.key, item.val

userdb.setProperty = (prop_name, nick, propValue) ->
  userdb.clearProperty prop_name, nick
  rec = userdb.get(nick)
  rec[prop_name] = propValue
  userdb.set nick, rec

userdb.getProperty = (prop_name, nick) ->
  rec = _(@aliases(nick)).find (item) -> _(item.val).has(prop_name)
  rec?.val[prop_name]

userdb.getArrayProperty = (prop_name, nick) ->
  _(@aliases(nick)).
  chain().
  map((item) -> item.val[prop_name] or []).
  flatten().
  value()

userdb.addArrayProperty = (prop_name, nick, prop_value) ->
  rec = userdb.get(nick)
  rec[prop_name] = _(rec[prop_name] or []).push(prop_value)
  userdb.set nick, rec

userdb.delArrayProperty = (prop_name, nick, number) ->
  found = _(@aliases(nick)).reduce((count, item) ->
    prop_values = item.val[prop_name] or []
    return count - prop_values.length if prop_values.length < count + 1
    prop_values.splice(count, 1)
    userdb.set item.key, item.val
    true
  , number)
  found is true

userdb.defineScalarProperty = (prop_name) ->
  userdb["clear_#{prop_name}"] = _.bind(userdb.clearProperty, userdb, prop_name)
  userdb["set_#{prop_name}"] = _.bind(userdb.setProperty, userdb, prop_name)
  userdb["get_#{prop_name}"] = _.bind(userdb.getProperty, userdb, prop_name)

userdb.defineArrayProperty = (prop_name) ->
  multi_name = inflection.pluralize prop_name
  userdb["clear_#{multi_name}"] = _.bind(userdb.clearProperty, userdb, multi_name)
  userdb["get_#{multi_name}"] = _.bind(userdb.getArrayProperty, userdb, multi_name)
  userdb["add_#{prop_name}"] = _.bind(userdb.addArrayProperty, userdb, multi_name)
  userdb["del_#{prop_name}"] = _.bind(userdb.delArrayProperty, userdb, multi_name)

module.exports = userdb
