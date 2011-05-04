var _ = global._  = require('./underscore');
var req = require('request');
var fs = require('fs');
Date = require('./date').DateJS;
var select = require('soupselect').select;
var htmlparser = require("htmlparser");
var qs = require('querystring');
var domUtils = htmlparser.DomUtils;


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
    stringify: function(obj) {
        return qs.stringify(obj).replace(/'/g, "%27");
    },
    select: function(dom, selector){
        return select(dom, selector);
    },
    invoke_: function(obj, method) {
        var args = _(arguments).slice(2);
        return _.map(obj, function(value) {
            value = _(value);
            return (method ? value[method] : value).apply(value, args);
        });
    },
    parse: function(text, cb){
        var parser = new htmlparser.Parser(new htmlparser.DefaultHandler(function(err, dom){
            cb(err, function(selector){ 
                return _(dom).chain().select(selector);
            }, text);
        }));
        parser.parseComplete(text);
    },
    parseRequest: function(options, cb) {
        this.request(options, function(error, response, body){
          if (error || response.statusCode !== 200) cb(error);
          else _.parse(body, cb); 
        })
    },
    text: function(elems) {
        if (!elems) return '';
        var textContent = function(elem) {
            return elem.type === 'text' ? elem.data : /\!\[CDATA\[(.*)\]\]/.exec(elem.data)[1]
        }
        return _(domUtils.getElements({
            tag_type: function(type){ 
                return type === 'text' || type === 'directive'
                }}, elems)).reduce(function(acc, elem){
            return acc + textContent(elem);
        }, '');
    },
    numbered: function(list) {
        return _(1).chain().range(list.length+1).zip(list).value();
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