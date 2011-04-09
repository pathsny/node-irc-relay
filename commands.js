var _ = require('./underscore');

(function(){
    exports.g = function(from, tokens, cb) {
        cb("google searched for " + tokens);
    };

    var tells = {};

    exports.tell = function(from, tokens, cb) {
        var to = _(tokens).head();
        var msg = _(tokens).tail().join(' ');
        if (to && msg) {
            tells[to] = _(tells[to] || []).push([from, msg])
            cb(from + ": Message Noted");
        } else {
            cb("Message not understood");
        }
    };
    
    var seen_data = {};
    
    exports.seen = function(from, tokens, cb) {
        var person = _(tokens).head();
        if (person && seen_data[person]) {
            cb(from + ": " + "Last saw " + person)
        }
    };
    
    exports.listeners = function(respond){
        return [
            //collect data for seen
            function(from, message) {
                console.log(from, message);
                // seen_data[from] = []
            },

            //convey messages
            function(from, message) {
                if (tells[from]) {
                    _(tells[from]).forEach(function(item){
                        respond(from + ": " + item[0] + " said '" + item[1] + "'");
                    })
                    delete tells[from];
                };
            }
        ]
    }
})()