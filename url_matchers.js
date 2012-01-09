var _ = require('underscore');
require('./utils');
var anidb = require('./anidb');

var _titleMatchers =  [
    function(t) {return t['xml:lang'] === 'en' && t.type === 'official'},
    function(t) {return t['xml:lang'] === 'en' && t.type === 'synonym'},
    function(t) {return t['xml:lang'] === 'x-jat' && t.type === 'synonym'}
]

exports.matchers =  {
    ytube: {
        regexes: [ /https?:\/\/www\.youtube\.com\/watch\?v=([^\s\t&]*)(?:.*?)\b/ , /https?:\/\/youtu\.be\/([^\s\t&\/]*)/],

        responder: function(from, message, match, respond) {
            var url = "http://gdata.youtube.com/feeds/api/videos/" + match[1] + "?" + _({v: 2,alt: 'jsonc'}).stringify();
            _.request({uri:url}, function (error, response, body) {
                if (!error && response.statusCode == 200) {
                    var res = JSON.parse(body).data;
                    respond("ah " + from + " is talking about " + _(res.category).articleize() + " video of " + res.title + ". The Tags are "  + _(res.tags).sentence() + ".");
                };
            });
        }
    },

    anidb: {
        regexes: [/http:\/\/anidb\.net\/perl-bin\/animedb.pl\?(?:.*)aid=(\d+)(?:.*)/],

        responder: function(from, message, match, respond) {
            anidb.getInfo(match[1], function(data){
                var titles = data.titles.title;
                var english_title_node = _(titles).find(_titleMatchers[0]) || _(titles).find(_titleMatchers[1]) || _(titles).find(_titleMatchers[2]);
                var msg = _(titles).find(function(t){return t.type === 'main'})['#'];
                if (english_title_node) {
                    msg += ' (' + english_title_node['#'] + ')';
                }
                respond('That anidb link is ' + msg);
                respond(data.splitDescription);
            });
        }
    },
  imdb: {
        regexes: [/http:\/\/www\.imdb\.com\/title\/(.*)\//],

        responder: function(from, message, match, respond) {
          var url = "http://www.imdbapi.com/?i=" + match[1];
	  _.request({uri:url}, function (error, response, body) {
	    if (!error && response.statusCode == 200) {
	      var res = JSON.parse(body);
              respond("ah "+ from + " is talking about " + res["Title"] + "("+ res["Year"] +") which is about " +res["Plot"]);
            }
          });
        }
    }

}

