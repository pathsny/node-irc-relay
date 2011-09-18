var TwitterNode = require('twitter-node').TwitterNode
var _ = require('underscore');
require('./utils');

var Twitter = exports.Twitter = function(users, settings, respond) {
    if (!(this instanceof Twitter)) return new Twitter(users, settings, respond);
    var twit = new TwitterNode({
      user: settings.user, 
      password: settings.password,
      headers: {'User-Agent': 'misaka'},
    });
    
    var follows = [];
    var updateFollows = function() { 
        follows = _(users.indexValues('twitter_id')).
        chain().
        without('undefined').
        map(function(index_value){
            return _(users.find('twitter_id', index_value)).map(function(user){
                return {twitter_id: index_value, nick: user.key};
            });
        }).
        flatten().value();
        twit.following = _(follows).chain().pluck('twitter_id').uniq().value();
    };
    updateFollows();
    
    var stream_end_expected = false;
    
    users.on('twitter follows changed',function(){
        stream_end_expected = true;
        updateFollows();
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
        console.log(tweet.text)
        reset_timeout();
        if (!_(tweet.entities.hashtags).chain().pluck('text').intersect(['irc', 'fb']).isEmpty().value())
        {
            _(follows).chain().filter(function(follow) {
                return follow.twitter_id === tweet.user.id_str;
            }).each(function(follow){
                respond(follow.nick + " from twitter: " + _(tweet.text).html_as_text());
            })
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

