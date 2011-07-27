var _ = require('underscore');
require('./utils');

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
            var url = "http://api.anidb.net:9001/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=" + match[1];
            _.parseRequest({uri: url, cache: match[1]}, function(err, $){
                if (!err) {
                    var english_name =  $('titles title[xml:lang="en"][type="official"]').text().value() ||
                    $('titles title[xml:lang="en"][type="synonym"]').first().text().value() ||
                    $('titles title[xml:lang="x-jat"][type="synonym"]').first().text().value();
                    var msg = $('titles title[type="main"]').text().value();
                    if (english_name) {msg += " (" + english_name + ")"};
                    respond("That anidb link is " + msg);
                }
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

