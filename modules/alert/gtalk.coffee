ROSTER_NS = "jabber:iq:roster"
subscription_types = ['subscribe', 'unsubscribe', 'subscribed', 'unsubscribed']

xmpp = require("simple-xmpp")
_ = require "../../utils"

class Gtalk
  constructor: ({user, password}, emitter) ->
    @_jid = "#{user}@gmail.com"
    @_iq_creator = new IqCreator()
    xmpp.on "error", (e) => console.log("gtalk error #{e}")
    xmpp.on "chat", emitter
    xmpp.on "online", @_on_online
    xmpp.on "stanza", @_detect_roster_set
    xmpp.on "stanza", @_detect_buddy_presence
    xmpp.on "subscribe", @_accept_if_buddy
    @_connect(password)

  is_online: =>
      xmpp.conn?.socket?.writable && xmpp.conn.streamOpened

  add_account: (gtalk_id, name, cb) =>
    if @_roster[gtalk_id]?.subscription
      @_subscribe_if_necessary gtalk_id, cb
    else
      @_add_to_roster gtalk_id, name, (result) =>
        if result
          @_subscribe_if_necessary gtalk_id, cb
        else
          cb('error')

  is_available: (gtalk_id) =>
    @is_messagable(gtalk_id) and @_is_active(gtalk_id)

  is_messagable: (gtalk_id) =>
    @is_online and _(['both', 'to']).include(@_roster[gtalk_id]?.subscription)

  message: (gtalk_id, msg) =>
    xmpp.send gtalk_id, msg

  _is_active: (gtalk_id) =>
    _(@_roster[gtalk_id].resources || {}).
    chain().
    values().
    any((r) => r isnt 'away').
    value()

  _is_from_me: (s) =>
    !s.attrs['from'] or s.attrs['from'] is @_jid

  _is_roster_stanza: (s) =>
    s.getChild('query')?.attrs['xmlns'] is ROSTER_NS

  _is_iq_set: (s) =>
    s.is('iq') and s.attrs["type"] is "set"

  _update_roster_item: (item) =>
    jid = item['jid']
    @_roster[jid] = _(@_roster[jid] || {}).extend(_(item).omit('jid'))

  _detect_roster_set: (s) =>
    if @_is_iq_set(s) and @_is_roster_stanza(s) and @_is_from_me(s)
      item = s.getChild('query').getChild('item').attrs
      if item.subscription is 'remove'
        delete @_roster[item.jid]
      else
        @_update_roster_item(item)

  _remove_roster_resource: (jid, resource) =>
    resources = @_roster[jid]?.resources || {}
    delete resources[resource]
    @_update_roster_item({jid: jid, resources: resources})

  _update_roster_resource: (jid, resource, state) =>
     resources = @_roster[jid]?.resources || {}
     resources[resource] = state
     @_update_roster_item({jid: jid, resources: resources})

  _accept_if_buddy: (gtalk_id) =>
    xmpp.acceptSubscription gtalk_id if @_roster[gtalk_id]

  _detect_buddy_presence: (s) =>
    if s.is('presence') and !_(subscription_types).include(s.attrs['type']) and s.attrs['from']
      [jid, resource] = s.attrs['from'].split('/')
      if s.attrs['type'] is 'unavailable'
        @_remove_roster_resource(jid, resource)
      else
        @_update_roster_resource(jid, resource, s.getChild('show')?.getText() || 'online')

  _connect: (password) =>
    xmpp.connect
      jid: @_jid,
      password: password,
      host: "talk.google.com"
      port: 5222

  _on_online: =>
    console.log("online on gtalk")
    @_roster = {}
    @_iq_creator.clear_queue()
    @_fetch_roster()

  _fetch_roster: =>
    @_iq_creator.create(type: "get").
      c("query", {xmlns: ROSTER_NS}).
      root().send (result) =>
        _(@_extract_roster(result)).each @_update_roster_item

  _extract_roster: (s) =>
    _(s.getChild("query").children).pluck('attrs')

  _subscribe_if_necessary: (gtalk_id, cb) =>
    if @is_messagable gtalk_id
      cb('done')
    else
      xmpp.subscribe gtalk_id
      cb('sent request')

  _add_to_roster: (gtalk_id, name, cb) =>
    @_iq_creator.create(type: 'set').
      c('query', xmlns: ROSTER_NS).
      c('item', {jid: gtalk_id, name: name}).
      root().
      send (result) =>
        cb(result.attrs["type"] is "result")


  x: xmpp


class IqCreator
  constructor: () ->
    @_id_no = 1
    @_iqs = {}
    xmpp.on 'stanza', (s) =>
      if s.is('iq') and @_iqs[s.attrs['id']]
        cb = @_iqs[s.attrs['id']]
        delete @_iqs[s.attrs['id']]
        cb(s)

  clear_queue: =>
    @_iqs = {}

  next_id: =>
    @_id_no++

  create: (attrs) =>
    id = "misaka_gtalk_#{@next_id()}"
    iq = new xmpp.Element("iq", _(attrs).extend(id: id))
    _(iq).extend({
      send: (cb) =>
        @_iqs[id] = cb
        xmpp.conn.send iq
    })

module.exports = Gtalk