contact_points = require './alert/contact_types'
Gtalk = require('./alert/gtalk')
Email = require('./alert/email')
_ = require '../utils'

class Alert
  constructor: ({@users, settings: {nick, modules: {alerts: {gmail}}}, @emitter}) ->
    @gtalk = new Gtalk(gmail, @on_gtalk_message)
    @email = new Email(gmail, nick)
    @setup_db()
    @commands = {alert: @command}
    @command._help = "send an alert to a member of the group who has added an alert option (gtalk id or email address) to me. !alert <nick> message"
    @private_commands = {}
    _(contact_points).each (params, pc) =>
      @users.defineScalarProperty params.property
      @private_commands[pc] = @create_private_command params

  setup_db: =>
    @users.defineScalarProperty "GtalkId"
    @users.defineScalarProperty "EmailAddress"
    @users.defineScalarProperty "PhoneNumber"
    @users.addIndex "GtalkId", (k, v) -> if v.GtalkId then [v.GtalkId] else []

  command: (from, tokens, cb) =>
    nick = _(tokens).head()
    unless nick and @users.get(nick) and tokens.length > 1
      return cb "alert <nick> message. <nick> must be a valid user"
    msg = "<#{from}> #{_(tokens).tail().join(' ')}"
    email_address = @users.get_EmailAddress(nick)
    gtalk_id = @users.get_GtalkId(nick)
    unless gtalk_id or email_address
      return cb "#{nick} has not configured any alert options"
    if email_address
      if gtalk_id and @gtalk.is_available(gtalk_id)
        @send_gtalk_message(gtalk_id, nick, msg, cb)
      else
        @send_email_message(email_address, nick, from, msg, cb)
    else
      if gtalk_id and @gtalk.is_messagable(gtalk_id)
        @send_gtalk_message(gtalk_id, nick, msg, cb)
      else
        cb "cannot send alert"

  send_email_message: (email_address, nick, from, msg, cb) =>
    @email.message email_address, nick, from, msg, (err) =>
      if err
        cb "sorry an error occured"
      else
        cb "sent an email alert to #{nick}"

  send_gtalk_message: (gtalk_id, nick, msg, cb) =>
    @gtalk.message(gtalk_id, msg)
    cb "sent a gtalk alert to #{nick}"

  on_gtalk_message: (gtalk_id, msg) =>
    nick = _(@users.find("GtalkId", gtalk_id)).pluck("key")[0]
    @emitter("<#{nick} (Gtalk)>: #{msg}", true) if nick

  create_private_command: ({property, regex, help}) =>
      pc = (from, tokens, cb) =>
        first = _(tokens).first()
        return unless @users.get from
        if first is 'clear'
          @clear_property property, from, cb
        else if first and regex.test(first)
          @set_property property, from, first, cb
        else cb help
      _(pc).extend(_help: help)

  clear_property: (property, from, cb) =>
    @users["clear_#{property}"] from
    cb "your #{property} has been cleared"

  set_gtalk_id: (from, value, cb) =>
    @gtalk.add_account value, from, (result) =>
      if result is 'error'
        cb "could not add your GtalkId"
      else
        @users["set_GtalkId"] from, value
        if result is 'done'
          cb "your GtalkId has been recorded as #{value}"
        else
          cb "your GtalkId has been recorded as #{value}. Please accept my friend request"


  set_property: (property, from, value, cb) =>
    if (property is 'GtalkId')
      @set_gtalk_id from, value, cb
    else
      @users["set_#{property}"] from, value
      cb "your #{property} has been recorded as #{value}"
module.exports = Alert

