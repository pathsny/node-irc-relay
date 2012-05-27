var xmpp = require('simple-xmpp');
var _ = require('underscore');
require('./utils');


var Gtalk = function() {
    this._configured = false;
    this._idNo = 0;
}

exports.gtalk = new Gtalk();

Gtalk.prototype.configure_with = function(users, display) {
    this._users = users;
    this._display = display;
    this._iqHash = {};
    this._awaitingSubscription = {};
}

Gtalk.prototype.relay = function(gtalk_id, message) {
    var nick = _(this._users.find('GtalkId', gtalk_id)).pluck('key')[0];
    if (nick) this._display('<' + nick + ' (Gtalk)>: ' + message);  
};

Gtalk.prototype._getId = function() {
    this._idNo++;
    return this._idNo; 
};

Gtalk.prototype.tryActiveAlert = function(nick, message, cb) {
    var gtalk_id = this._users.getGtalkId(nick);
    if (!this._configured || !gtalk_id) {
        cb(false);
        return
    }
    var probe_function = function(state) {
        if (probe_function.fired) return;
        if (state !== 'online' && state !== 'dnd') cb(false)
        else {
            xmpp.send(gtalk_id, message);
            cb(true);
        }
        probe_function.fired = true;
    }
    
    xmpp.probe(gtalk_id, probe_function);
    setTimeout(probe_function, 10000);
};

Gtalk.prototype.tryAlert = function(nick, message) {
    var gtalk_id = this._users.getGtalkId(nick);
    if (!gtalk_id || !this._configured) return false;
    xmpp.send(gtalk_id, message);
    return true;
}

Gtalk.prototype._makeIq = function(attrs) {
    var iqId = this._getId().toString();
    var iq = new xmpp.Element('iq', _(attrs).extend({
        id: iqId
    }));
    var self = this;
    iq.send = function(cb) {
        self._iqHash[iqId] = _(cb).bind(self);
        xmpp.conn.send(iq);
    }
    return iq;
}

Gtalk.prototype._addJid = function(nick, gtalk_id, cb) {
    this._users.setGtalkId(nick, gtalk_id);
    cb('your gtalk id has been recorded as ' + gtalk_id);
}

Gtalk.prototype._addItemToRosterAndProcess = function(nick, gtalk_id, cb) {
    this._makeIq({
        type: 'set'
        }).c('query',{
          xmlns: 'jabber:iq:roster'  
        }).c('item', {
            jid: gtalk_id,
            name: nick
        }).root().send(function(result){
           if (result.attrs['type'] === 'result') this._subscribeToPresenceAndProcess(nick, gtalk_id, cb);
            else cb('your gtalk id could not be added');
        });
}

Gtalk.prototype._subscribeToPresenceAndProcess = function(nick, gtalk_id, cb) {
    xmpp.conn.send(new xmpp.Element('presence',{
      to: gtalk_id,
      type: 'subscribe'  
    }));
    this._awaitingSubscription[gtalk_id] = _(this._addJid).bind(this, nick, gtalk_id, cb);
    cb('a request has been sent to ' + gtalk_id + '. Please approve it to set this gtalk id');
}

Gtalk.prototype.addAccount = function(nick, gtalk_id, cb) {
    this._makeIq({
        type: 'get'
    }).c('query', {
        xmlns: 'jabber:iq:roster'
    }).root().send(function(response){
        var rosteritem = response.getChild('query').getChildByAttr('jid', gtalk_id);
        if (!rosteritem) {
            this._addItemToRosterAndProcess(nick, gtalk_id, cb);
            return;
        }
        if (rosteritem.attrs['subscription'] === 'both') this._addJid(nick, gtalk_id, cb);
        else this._subscribeToPresenceAndProcess(nick, gtalk_id, cb);
    })
};

Gtalk.prototype.login = function(options) {
    this._options = options;
    var self = this;
    xmpp.on('chat', function(from, message){
        self.relay(from, message);
    });
    
    xmpp.on('online', function(){
        console.log('online on gtalk');
        self._configured = true;
    });
    
    xmpp.on('error', function(e) {
    	  console.error('gtalk error ' + e);
    });
    
    xmpp.on('stanza', function(s){
        if (s.is('iq') && self._iqHash[s.attrs['id']]) {
            var fn = self._iqHash[s.attrs['id']];
            delete self._iqHash[s.attrs['id']];
            fn(s);
        }
        if (s.is('presence') && s.attrs['type'] === 'subscribed') {
            var fn = self._awaitingSubscription[s.attrs['from']];
            delete self._awaitingSubscription[s.attrs['from']];
            fn();
        }
    });
          
    xmpp.on('disconnect', function(){
        self._configured = false;
        self.gtalk.login(this._options);
    });      
    
    xmpp.connect({
        jid         : options.user + '@gmail.com',
        password    : options.password,
        host        : 'talk.google.com',
        port        : 5222
    });

}





