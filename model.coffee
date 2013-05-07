userdb = require("dirty")("./data/user.db")
uuid = require("node-uuid")
_ = require("underscore")
require "./utils"
userdb.addIndex "nickId", (k, v) ->
  v.nickId

userdb.addIndex "token", (k, v) ->
  v.token

userdb.addIndex "twitter_id", (k, v) ->
  v.twitter_id

userdb.addIndex "GtalkId", (k, v) ->
  v.GtalkId

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

_(["msg", "tell"]).each (type) ->
  userdb["add" + _(type).capitalize()] = (nick, data) ->
    rec = userdb.get(nick)
    collection = rec[type + "s"] or []
    collection.push data
    rec[type + "s"] = collection
    rec.newMsgs = true  if type is "msg"
    userdb.set nick, rec

_(["msgs", "tells"]).each (type) ->
  userdb["get" + _(type).capitalize()] = (nick) ->
    _(@aliases(nick)).chain().map((item) ->
      item.val[type] or []
    ).flatten().value()

userdb.unSetNewMsgFlag = (nick) ->
  newMsgExists = false
  _(@aliases(nick)).each (item) ->
    rec = item.val
    newMsgExists = true  if rec.newMsgs
    rec.newMsgs = false
    userdb.set item.key, rec

  newMsgExists

userdb.deleteMsg = (nick, number) ->
  _(@aliases(nick)).any (item) ->
    msgs = item.val.msgs or []
    if msgs.length > number
      msgs.splice number, 1
      userdb.set item.key, item.val
      true
    else
      number -= msgs.length


userdb.clearTells = (nick) ->
  _(@aliases(nick)).each (item) ->
    rec = item.val
    rec.tells = []
    userdb.set item.key, rec


userdb.createToken = (nick) ->
  rec = userdb.get(nick)
  return  if rec.status isnt "online"
  rec["token"] = uuid()
  userdb.set nick, rec
  rec["token"]

userdb.validToken = (token) ->
  return  unless token
  _(userdb.find("token", token)).first()

userdb.clearProperty = (propName, nick) ->
  _(@aliases(nick)).find (item) ->
    rec = _(item.val).clone()
    delete rec[propName]

    userdb.set item.key, rec


userdb.setProperty = (propName, nick, propValue) ->
  userdb.clearProperty propName, nick
  rec = _(userdb.get(nick)).clone()
  rec[propName] = propValue
  userdb.set nick, rec

userdb.getProperty = (propName, nick) ->
  rec = _(@aliases(nick)).find((item) ->
    item.val[propName]
  )
  rec and rec.val[propName]

_(["PhoneNumber", "TwitterAccount", "EmailAddress", "GtalkId"]).each (thing) ->
  userdb["clear" + thing] = _.bind(userdb.clearProperty, userdb, thing)
  userdb["set" + thing] = _.bind(userdb.setProperty, userdb, thing)
  userdb["get" + thing] = _.bind(userdb.getProperty, userdb, thing)

exports.start = (fn) ->
  userdb.on "load", ->
    fn userdb

