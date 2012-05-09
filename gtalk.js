var xmpp = require('node-xmpp');
var EventEmitter = require('events').EventEmitter;
var _ = require('underscore');
require('./utils');
var util = require('util');


var Gtalk = function() {
    this._configured = false;
}

util.inherits(Gtalk, EventEmitter);
exports.gtalk = new Gtalk();

Gtalk.prototype.configure_with = function(users, display) {
    this._users = users;
    this._display = display;
}

Gtalk.prototype.relay = function(gtalk_id, message) {
    var nick = _(this._users.find('GtalkId', gtalk_id)).pluck('key')[0];
    console.log(nick, message);
    if (nick) this._display('<' + nick + ' (Gtalk)>: ' + message);  
};

Gtalk.prototype.login = function(options) {
    this._options = options;
    var self = this;
    var conn = this.conn = new xmpp.Client({
        jid         : options.user + '@gmail.com',
        password    : options.password,
        host        : 'talk.google.com',
        port        : 5222
    });
    conn.on('online', function() {
        this._configured = true;
        conn.send(new xmpp.Element('presence', { }).
        c('show').t('chat').up().
        c('status').t('Misaka the IRC Bot'));
    })
    
    conn.on('stanza', function(stanza){
        if (stanza.is('message') &&
        stanza.attrs.type !== 'error') {
            self.relay(stanza.attrs.from.split('/')[0], stanza.getChildText('body'));
        }
    });
    
    conn.on('error', function(e) {
    	  console.error('gtalk error ' + e);
    });
          
    conn.on('disconnect', function(){
        self.gtalk.login(this._options);
    });      
}





