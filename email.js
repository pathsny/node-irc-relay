var nodemailer = require('nodemailer');
var _ = require('underscore');
require('./utils');

var Email = exports.Email = function(options) {
    this._options = options;
}

Email.prototype.send = function(email_options, cb) {
    _(email_options).extend(this._options);
    var smtpTransport = nodemailer.createTransport("SMTP",{
        service: "Gmail",
        auth: {
            user: email_options.user,
            pass: email_options.pass
        }
    });
    var mailOptions = {
        from: email_options.clientName + " <" + email_options.user + ">",
        to: email_options.to,
        subject: email_options.subject,
        text: email_options.text
    };
    smtpTransport.sendMail(mailOptions, function(error, response){
        cb(error)
        smtpTransport.close();
    });
    
}