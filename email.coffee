nodemailer = require("nodemailer")
_ = require("underscore")
require "./utils"

class Email
  constructor: (@_options) ->

  send: (email_options, cb) =>
    _(email_options).extend @_options
    smtpTransport = nodemailer.createTransport("SMTP",
      service: "Gmail"
      auth:
        user: email_options.user
        pass: email_options.pass
    )
    mailOptions =
      from: email_options.clientName + " <" + email_options.user + ">"
      to: email_options.to
      subject: email_options.subject
      text: email_options.text

    smtpTransport.sendMail mailOptions, (error, response) ->
      cb error
      smtpTransport.close()

module.exports = Email
