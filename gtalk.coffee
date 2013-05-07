xmpp = require("simple-xmpp")
_ = require("underscore")
require "./utils"
Gtalk = ->
  @_configured = false
  @_idNo = 0

exports.gtalk = new Gtalk()
Gtalk::configure_with = (users, display) ->
  @_users = users
  @_display = display
  @_iqHash = {}
  @_awaitingSubscription = {}

Gtalk::relay = (gtalk_id, message) ->
  nick = _(@_users.find("GtalkId", gtalk_id)).pluck("key")[0]
  @_display "<" + nick + " (Gtalk)>: " + message  if nick

Gtalk::_getId = ->
  @_idNo++
  @_idNo

Gtalk::tryActiveAlert = (nick, message, cb) ->
  gtalk_id = @_users.getGtalkId(nick)
  if not @_configured or not gtalk_id
    cb false
    return
  probe_function = (state) ->
    return  if probe_function.fired
    unless state isnt "online" and state isnt "dnd"
      xmpp.send gtalk_id, message
      cb true
    probe_function.fired = true

  xmpp.probe gtalk_id, probe_function
  setTimeout probe_function, 10000

Gtalk::tryAlert = (nick, message) ->
  gtalk_id = @_users.getGtalkId(nick)
  return false  if not gtalk_id or not @_configured
  xmpp.send gtalk_id, message
  true

Gtalk::_makeIq = (attrs) ->
  iqId = @_getId().toString()
  iq = new xmpp.Element("iq", _(attrs).extend(id: iqId))
  self = this
  iq.send = (cb) ->
    self._iqHash[iqId] = _(cb).bind(self)
    xmpp.conn.send iq

  iq

Gtalk::_addJid = (nick, gtalk_id, cb) ->
  @_users.setGtalkId nick, gtalk_id
  cb "your gtalk id has been recorded as " + gtalk_id

Gtalk::_addItemToRosterAndProcess = (nick, gtalk_id, cb) ->
  @_makeIq(type: "set").c("query",
    xmlns: "jabber:iq:roster"
  ).c("item",
    jid: gtalk_id
    name: nick
  ).root().send (result) ->
    if result.attrs["type"] is "result"
      @_subscribeToPresenceAndProcess nick, gtalk_id, cb
    else
      cb "your gtalk id could not be added"


Gtalk::_subscribeToPresenceAndProcess = (nick, gtalk_id, cb) ->
  xmpp.conn.send new xmpp.Element("presence",
    to: gtalk_id
    type: "subscribe"
  )
  @_awaitingSubscription[gtalk_id] = _(@_addJid).bind(this, nick, gtalk_id, cb)
  cb "a request has been sent to " + gtalk_id + ". Please approve it to set this gtalk id"

Gtalk::addAccount = (nick, gtalk_id, cb) ->
  @_makeIq(type: "get").c("query",
    xmlns: "jabber:iq:roster"
  ).root().send (response) ->
    rosteritem = response.getChild("query").getChildByAttr("jid", gtalk_id)
    unless rosteritem
      @_addItemToRosterAndProcess nick, gtalk_id, cb
      return
    if rosteritem.attrs["subscription"] is "both"
      @_addJid nick, gtalk_id, cb
    else
      @_subscribeToPresenceAndProcess nick, gtalk_id, cb


Gtalk::login = (options) ->
  @_options = options
  self = this
  xmpp.on "chat", (from, message) ->
    self.relay from, message

  xmpp.on "online", ->
    console.log "online on gtalk"
    self._configured = true

  xmpp.on "error", (e) ->
    console.error "gtalk error " + e

  xmpp.on "stanza", (s) ->
    if s.is("iq") and self._iqHash[s.attrs["id"]]
      fn = self._iqHash[s.attrs["id"]]
      delete self._iqHash[s.attrs["id"]]

      fn s
    if s.is("presence") and s.attrs["type"] is "subscribed"
      fn = self._awaitingSubscription[s.attrs["from"]]
      delete self._awaitingSubscription[s.attrs["from"]]

      fn()

  xmpp.on "disconnect", ->
    self._configured = false
    self.gtalk.login @_options

  xmpp.connect
    jid: options.user + "@gmail.com"
    password: options.password
    host: "talk.google.com"
    port: 5222

