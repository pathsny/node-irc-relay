// var commands_lib = require('./commands');
// var commands = commands_lib.Commands(undefined, undefined);

var _ = require('underscore');
_.mixin(require('underscore.date'));

console.log('about')
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
console.log('to')

console.log(_.now().subtract({s: 35}).fromNow());

// require('./utils');

// 
// 
// var url = "http://anisearch.outrance.pl/?task=search&query=battle%20angel";
//  _.request({uri: url}, function(error, response, body) {
//      _(body).parse(function(err, $, text){
//          console.log(text)
//          console.log('hi')
//          var aid = $('anime').first().value().attribs['aid'];
//          var url = "http://api.anidb.net:9001/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=" + aid;
//          _.parseRequest({uri: url, cache: aid}, function(err, $){
//              if (!err) {
//                  var english_name =  $('titles title[xml:lang="en"][type="official"]').text().value() ||
//                  $('titles title[xml:lang="en"][type="synonym"]').first().text().value() ||
//                  $('titles title[xml:lang="x-jat"][type="synonym"]').first().text().value();
//                  var msg = $('titles title[type="main"]').text().value();
//                  if (english_name) {msg += " (" + english_name + ")"};
//              }
//          });
//      })
//  })
 
 
 // _.parse("<b><a bar='xa'>1</a><a bar='xb'>2</a><a bar='yb'>3</a></b>", function(err, $){
 //   console.log($('a[bar^="x"][bar$="b"]').text())  
 // })
// 
//         jsdom.jQueryify(window, 'http://code.jquery.com/jquery-1.5.min.js' , function() {
//             console.log("contents of a.the-link:", window.$("title[exact='exact']").first()[0].childNodes.length);
// 
//         var titles = $(body).find("title[exact='exact']").first()[0];
//         console.log(titles.innerHTML)
//         console.log(titles.outerHTML)
//         console.log(titles.size())
//         if (titles.size() === 0) console.log('unknown');
//         else {
//             if (titles.size() === 1) console.log(titles.text());
//             else titles.each(function(i, title){
//                 console.log($(title).text());
//             })
//         }    
//     }
// })

// var url = "http://api.anidb.net:9001/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=8180";
//  _.request({uri: url, cache: "8180"}, function(error, response, body) {
//      if (!error & response.statusCode == 200) {
//          console.log(response.headers)
//          console.log(body)
//          var res = $(body);
//          console.log($("<a>1</a>").html())
//          console.log($(body).find("titles > title[type='main']").html());
//          console.log($(body).find("titles > title[xml\\:lang='en'][type='official']").html());
//      };
//  });

//  var req = http.get({
//   host: "api.anidb.net", 
//   port: "9001", 
//   path: "/httpapi?request=anime&client=misakatron&clientver=1&protover=1&aid=8181"
//  }, function(response) {
//   console.log("response headers:", response.headers);
// });
// 




