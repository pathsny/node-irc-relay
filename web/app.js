var connect = require('connect');
var gzippo = require('gzippo');
var ejs = require('ejs');
var fs = require('fs');
var _ = require('underscore');
require('../utils');
var exec = require('child_process').exec;
var url = require('url');
var qs = require('querystring');
var socket_io = require('socket.io');

var Server = exports.Server = function(users, nick, port, textEmittor, sendChat) {
    var views = _(['index', 'login', 'search', 'video']).inject(function(views, page){
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
            app.get('/video', function(req, res, next){
                var aliases = users.aliases(users.validToken(req.cookies['mtoken']).key);
                if (_(aliases).any(function(item){
                    return item.val.status === 'online';
                })) {
                    res.end(ejs.render(views['video'], {
                        locals: {
                            nick: users.validToken(req.cookies['mtoken']).key
                        }
                    }))
                } else {
                    res.end(ejs.render("You must be in the channel to participate"))
                }
            })
        })
    );
    console.log("starting webserver on port " + port)
    app.listen(Number(port));

    var io = socket_io.listen(app)
    io.configure( function(){
        io.enable('browser client minification');  
        io.enable('browser client etag');          
        io.enable('browser client gzip');
        io.set('log level', 1);
    });
    
    var peers = {};
    var id = 0;
    var getNick = function(socket) {
        var cookie_string = socket.handshake.headers.cookie;
        var parsed_cookies = connect.utils.parseCookie(cookie_string);
        var nick = users.validToken(parsed_cookies['mtoken']).key;
        id ++;
        return nick + ' ' + id;
    }
    
    io.sockets.on('connection', function(socket){
        var nick = getNick(socket);
        socket.broadcast.emit('user connected',  nick);
        socket.emit('existing users', _(peers).keys());
        peers[nick] = socket;
        socket.on('disconnect', function(){
            delete peers[nick];
            socket.broadcast.emit('user disconnected', nick);
        });
        socket.on('chat_message', function(m){
            sendChat('<' + nick.split(' ')[0] + '|Video>: ', m);
        });
        socket.on('signalling message', function(data){
            var otherSocket = peers[data.user];
            if (!otherSocket) {
                console.log('cannot find socket of user ', data.user)
                return
            }
            otherSocket.emit('signalling message', {
                user: nick,
                data: data.data
            })
        })
    });
    textEmittor.on('text', _(io.sockets.emit).bind(io.sockets, 'text'));
}




