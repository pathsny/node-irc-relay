var TwitterNode = require('twitter-node').TwitterNode
var _ = require('underscore');
require('./utils');


var Twitter = exports.Twitter = function(settings, respond) {
    if (!(this instanceof Twitter)) return new Twitter(settings, respond);
    this.respond = respond;
    
    nickmap = {
        64939976: 'path[l]'
    }
    
    var twit = new TwitterNode({
      user: 'misakabot', 
      password: settings["twitter_password"],
      follow: [64939976],                  
    });

    twit.params['count'] = 0;
    twit.headers['User-Agent'] = 'misaka';
    
    twit.addListener('error', function(error) {
      console.log(error.message);
    });

    twit
      .addListener('tweet', function(tweet) {
          if (tweet.user.id === 64939976 && !_(tweet.entities.hashtags).chain().pluck('text').intersect(['irc', 'fb']).isEmpty().value())
          {
              var nick = nickmap[tweet.user.id];
              respond(nick + " from twitter: " + tweet.text);
          }
    })

      .addListener('limit', function(limit) {
        console.log("LIMIT: " + sys.inspect(limit));
      })

      .addListener('delete', function(del) {
        console.log("DELETE: " + sys.inspect(del));
      })

      .addListener('end', function(resp) {
        console.log("wave goodbye... " + resp.statusCode);
      })

      .stream();
}


// you can pass args to create() or set them on the TwitterNode instance

