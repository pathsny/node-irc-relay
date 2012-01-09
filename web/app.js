var connect = require('connect');
var gzippo = require('gzippo');
var ejs = require('ejs');
var fs = require('fs');
var _ = require('underscore');
require('../utils');
var exec = require('child_process').exec;
var url = require('url');
var qs = require('querystring');

var Server = exports.Server = function(users, nick, port) {
    if (!(this instanceof Server)) return new Server(users, nick, port);
    
    var views = _(['index', 'login', 'search', 'helloworld']).inject(function(views, page){
        return _({}).chain().extend(views).tap(function(views){
            views[page] = fs.readFileSync(__dirname + '/views/' + page + '.ejs', 'utf8');
        }).value();
    },{});
    
    var auth = function(req, res, next) {
        if (users.validToken(req.cookies['mtoken'])) {
            next()
            return 
        }
        else if (users.validToken(req.body && req.body['mtoken'])) {
            var cookieString = ejs.render('mtoken=<%=mtoken%>; Max-Age=3153600000', {
                locals: {
                    mtoken: req.body['mtoken']
                }
            }); 
            res.writeHead(302, {Location: (req.body['ReturnUrl'] || '/'), 
            'Set-Cookie': cookieString});
            res.end();
            return
        }
        res.end(ejs.render(views['login'], {
            locals: {
                title: 'MISAKA logs',
                ReturnUrl: req.url,
                nick: nick
            }
        }));    
    };
    
    var search = function(req, res, next){
        var parsedUrl = qs.parse(url.parse(req.url).query);
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8;'});
        var search = parsedUrl['q'];
        var render = function(res, search, results) {
            res.end(ejs.render(views['search'], {
                locals : { 
                    title: 'MISAKA logs',
                    search: search,
                    results: results
                }
            }));
        }
        if (search) {
            var cmd = "egrep -h -m 10 '\\b(" + _(search.split(' ')).join('|') + ")\\b' data/irclogs/*.log";
            exec(cmd, function(error, stdout, stderr) { 
                var results = stdout === '' ? [] : _(stdout.split('\n')).map(function(l){
                    var t = l.indexOf(',');
                    var timestamp = Number(l.slice(1,t));
                    return {
                        timestamp: timestamp,
                        date: _.date(timestamp).format("dddd, MMMM Do YYYY, hh:mm:ss"),
                        msg: l.slice(t+2,-2)
                    };
                });
                render(res, search, results);
            });
        }
         else {
            render(res, '', []);
        }
    };
    
    var app = connect.createServer(
        connect.favicon(__dirname + '/public/favicon.ico'),
        connect.bodyParser(),
        connect.cookieParser(),
        auth,
        gzippo.staticGzip(__dirname + '/public'),
        gzippo.staticGzip(__dirname + '/../data/irclogs'),
        connect.router(function(app){
            app.get('/', function(req, res, next){
                res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8;'});
                res.end(ejs.render(views['index'], {
                    locals : { 
                        title: 'MISAKA logs'
                    }
                }));
            });
            app.get('/search', search);
            app.get('/helloworld', function(req, res, next){
                res.end(ejs.render(views['helloworld']))
            })
        })
    );
    console.log("starting webserver on port " + port)
    app.listen(Number(port));
    // var nowjs = require("now");
    // var everyone = nowjs.initialize(app);
    // 
    // everyone.now.distributeMessage = function(message){
    //   everyone.now.receiveMessage(this.now.name, message);
    // };
}




