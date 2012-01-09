var _ = global._  = require('underscore');
_.mixin(require('underscore.date'));
var req = require('request');
var fs = require('fs');
var select = require('soupselect').select;
var qs = require('querystring');
var sanitizer = require('sanitizer');
var zlib = require('zlib');
var xmlParser = new require('xml2js').Parser({mergeAttrs: true});

_.date().customize({relativeTime : {
        future: "in %s",
        past: "%s ago",
        s: "less than a minute",
        m: "about a minute",
        mm: "%d minutes",
        h: "about an hour",
        hh: "about %d hours",
        d: "a day",
        dd: "%d days",
        M: "about a month",
        MM: "%d months",
        y: "about a year",
        yy: "%d years"
}});
_.mixin({
    sentence: function(words) {
        if (!words || words.length === 1) return words;
        var beginning = _(words).first(words.length - 1);
        return beginning.join(', ') + " and " + _(words).last();
    },
    capitalize: function(word) {
        return word.charAt(0).toUpperCase() + word.slice(1)
    },
    rand: function(list) {
        return list[Math.floor(Math.random()*list.length)];
    },
    zipWithIndex: function(list) {
        return _.zip(list, _.range(list.length));
    },
    articleize: function(word) {
        return (/^[aeiou]/i.test(word) ? "an" : "a") + " " + word;
    },
    stringify: function(obj) {
        return qs.stringify(obj).replace(/'/g, "%27");
    },
    firstMatchIfExists: function(string, pattern) {
        var match = pattern.exec(string)
        return match ? match[1] : string;
    },
    invoke_: function(obj, method) {
        var args = _(arguments).slice(2);
        return _.map(obj, function(value) {
            value = _(value);
            return (method ? value[method] : value).apply(value, args);
        });
    },
    html_as_text: function(text) {
        return sanitizer.unescapeEntities(text.replace(/<[^>]*>/g, ''));
    },
    partitionAt: function(list, iterator, context) {
      for (var i=0; i<list.length; i++) {
          if (!iterator.call(context, list[i])) break;
      };
      return [list.slice(0, i), list.slice(i)];
    },
    numbered: function(list) {
        return _(1).chain().range(list.length+1).zip(list).value();
    },
    gmtDate: function(date) {
        if (date.date) date = date.date;
        var yyyy = '' + date.getUTCFullYear();
        var mm = '' + date.getUTCMonth();
        if (mm.length === 1) mm = '0' + mm;
        var dd = '' + date.getUTCDate();
        if (dd.length === 1) dd = '00' + dd;
        return yyyy + "_" + mm + "_" + dd;
    },
    _streamToString: function(stream, cb) {
        var str = '';
        stream.on('data', function(c){
            str += c.toString();
        });
        stream.on('end', function(){
            cb(str);
        });
    },
    _compressedReq: function(options, cb) {
        var r = req(_(options).extend({"headers": {"Accept-Encoding": "gzip, deflate"}}));
        r.on('response', function(response){
            var headers = response.headers['content-encoding'];
            var stream = (headers && (headers.search('gzip') !== -1 || headers.search('deflate') !== -1)) ?
            r.pipe(zlib.createUnzip()) : r;
            _._streamToString(stream, function(data){
                cb(undefined, response, data);
            });
        });
        r.on('error', function(err){
            cb(err);
        })
    },
    inSlicesOf: function(items, size) {
        var slices = Math.ceil(items.length/size);
        return _(1).range(slices+1).map(function(n){
            var start = (n-1)*size;
            return items.slice(start, start + size);
        });
    },
    requestXmlAsJson: function(options, cb) {
        this.request(options, function(error, response, body){
          if (error || response.statusCode !== 200) cb(error);
          else xmlParser.parseString(body, function(err, result){
                cb(err, result);
          });  
        });
    },
    request: function(options, cb) {
        var cache;
        if (options.cache) cache = './data/cache/' + options.cache;
        var handle_resp = function(error, response, body) {
            if (!error && options.cache) {
                var encoding = options.encoding || 'utf8';
                fs.writeFile(cache, JSON.stringify([{
                    httpVersion: response.httpVersion, 
                    headers: response.headers, 
                    statusCode: response.statusCode}, body]));
            };
            cb(error, response, body); 
        };
        var http_req = function() {
            _._compressedReq(options, function(error, response, body){
                handle_resp(error, response, body)
            });
        };
        if (!cache) return http_req();
        fs.stat(cache, function(err, stats){
            if (!err && stats.mtime >= _.now().subtract({w: 1}).date) {
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
      },
      displayChatMsg: function(from, msg) {
          var actionMatch = /^\u0001ACTION(.*)\u0001$/.exec(msg);
          if (actionMatch) {
              return "*" + from + actionMatch[1];
          } else {
              return "<" + from + "> " + msg;
          }
      },
      automated: function(msg) {
          return /\u000311.•\u000310\u0002«\u0002\u000311WB\u000310 \u0002\(\u000f\u0002.+\u000310\)\u0002 \u000311WB\u000310\u0002»\u0002\u000311•. \u000310\u0002-\u000f \u001f/.test(msg)
      },
      invoke_: function(list, functionName) {
          var args = _(arguments).slice(2);
          return _(list).map(function(item){
              return this[functionName].apply(this, _([item]).concat(args));
          }, this);
      }
  })