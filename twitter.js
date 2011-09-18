var TwitterNode = require('twitter-node').TwitterNode
var _ = require('underscore');
require('./utils');

var nickmap = {
    64939976: 'path[l]',
    119446216: 'preethi',
    34292195: 'iwikiwi',
    29061687: 'Stattrav'
}

var nick_ids = _(nickmap).chain().keys().map(function(i){return Number(i)}).value();

var Twitter = exports.Twitter = function(users, settings, respond) {
    if (!(this instanceof Twitter)) return new Twitter(users, settings, respond);
    var getFollows = function() { return _(users.indexValues('twitter_id')).without('undefined')};
    
    var twit = new TwitterNode({
      user: settings.user, 
      password: settings.password,
      follow: getFollows(),
      headers: {'User-Agent': 'misaka'},
    });
    var stream_end_expected = false;
    
    users.on('twitter follows changed',function(){
        stream_end_expected = true;
        twit.following = getFollows();
        twit.stream();
    });
    
    twit.on('error', function(error) { console.log("twitter ERROR: " + error.message)});
    
    var timeout_sec = undefined;
    var first_failure_has_occurred = false;
    
    var reset_timeout = function() { first_failure_has_occurred = false;};
    var reset = function(){twit.stream()};

    twit.on('limit', reset_timeout).
    on('delete', reset_timeout).
    on('tweet', function(tweet) {
        reset_timeout();
        if (_(nick_ids).contains(tweet.user.id) && !_(tweet.entities.hashtags).chain().pluck('text').intersect(['irc', 'fb']).isEmpty().value())
        {
            var nick = nickmap[tweet.user.id];
            respond(nick + " from twitter: " + tweet.text);
        }
    }).
    on('end', function(resp) {
        if (stream_end_expected) {
            stream_end_expected = false;
            return;
        }
        console.log("wave goodbye... " + resp.statusCode);
        if (resp.statusCode === 420) {
            if (first_failure_has_occurred) {
                timeout_sec =  timeout_sec*2;
                _.delay(reset, timeout_sec);
            } else {
                first_failure_has_occurred = true;
                timeout_sec = _(20).chain().range(41).rand().value();
                _.delay(reset, timeout_sec);
            }
        } else reset();
    }).
    stream();
}

