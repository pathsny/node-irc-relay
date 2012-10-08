var _ = require('underscore');
require('./utils');
module.exports = {
    getInfo: function(aid, cb) {
        var url = "http://api.anidb.net:9001/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=" + aid;
        _.requestXmlAsJson({uri: url, cache: aid}, function(err, data){
            if (err) console.error(err);
            else {
                if (!data.description) {
                    data.splitDescription = "no data provided";
                    cb(data);
                    return;
                }
                var desc = data.description.split('\n');
                data.splitDescription = _(desc).chain().
                invoke_('inSlicesOf', 400).
                flatten().
                join('\n')
                .value();
                cb(data);
            }
        });
    }
}