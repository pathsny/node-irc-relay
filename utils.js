var _ = global._  = require('./underscore');
var req = require('request');
var fs = require('fs');
Date = require('./date').DateJS;

_.mixin({
    sentence: function(words) {
        if (!words || words.length === 1) return words;
        var beginning = _(words).first(words.length - 1);
        return beginning.join(', ') + " and " + _(words).last();
    },
    rand: function(list) {
        return list[Math.floor(Math.random()*list.length)];
    },
    articleize: function(word) {
        return (/^[aeiou]/i.test(word) ? "an" : "a") + " " + word;
    },
    escape_quote: function(str) {
        return str.replace(/'/g, "%27");
    },
    request: function(options, cb) {
        var cache;
        if (options.cache) cache = './data/cache/' + options.cache;
        var http_req = function() {
            req(options, function(error, response, body){
                if (!error && options.cache) {
                    var encoding = options.encoding || 'utf8';
                    fs.writeFile(cache, JSON.stringify([{
                        httpVersion: response.httpVersion, 
                        headers: response.headers, 
                        statusCode: response.statusCode}, body]));
                };
                cb(error, response, body); 
            });
        };
        if (!cache) return http_req();
        fs.stat(cache, function(err, stats){
            if (!err && stats.mtime.between(Date.now().addWeeks(-1), Date.now())) {
                fs.readFile(cache, function (err, data) {
                    if (err) http_req()
                    else {
                        var result = JSON.parse(data);
                        cb(undefined,result[0], result[1]);
                    }
                });
            } else {
                return http_req();
            }
        }); 
      }
  })