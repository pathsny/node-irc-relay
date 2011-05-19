var TwitterNode = require('twitter-node').TwitterNode
var _ = require('underscore');
require('./utils');


var Twitter = exports.Twitter = function(settings, respond) {
    if (!(this instanceof Twitter)) return new Twitter(settings, respond);
    this.respond = respond;
    
    nickmap = {
        64939976: 'path[l]',
        119446216: 'preethi',
        34292195: 'iwikiwi',
        29061687: 'Stattrav'
    }
    
    var nick_ids = _(nickmap).chain().keys().map(function(i){return Number(i)}).value();
    
    var twit = new TwitterNode({
      user: 'misakabot', 
      password: settings["twitter_password"],
      follow: nick_ids,                  
    });
    
    twit.params['count'] = 0;
    twit.headers['User-Agent'] = 'misaka';
    
    twit.addListener('error', function(error) {
      console.log(error.message);
    });

    twit
      .addListener('tweet', function(tweet) {
          if (_(nick_ids).contains(tweet.user.id) && !_(tweet.entities.hashtags).chain().pluck('text').intersect(['irc', 'fb']).isEmpty().value())
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
        new Twitter(settings, respond);
      })

      // .stream();
}


// you can pass args to create() or set them on the TwitterNode instance

