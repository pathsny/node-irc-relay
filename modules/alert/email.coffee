nodemailer = require("nodemailer")
_ = require "../../utils"

class Email
  constructor: ({@user, @password}, @botname) ->

  message: (email_address, nick, from, msg, cb) =>
    smtpTransport = nodemailer.createTransport "SMTP",
      service: "Gmail"
      auth: {user: @user, pass: @password}

    mailOptions =
      from: "#{@botname} Alerts <#{@user}>"
      to: "#{nick} <#{email_address}>"
      subject: "Alert Email from #{from}"
      text: msg

    smtpTransport.sendMail mailOptions, (error, response) ->
      cb error
      smtpTransport.close()

module.exports = Email
