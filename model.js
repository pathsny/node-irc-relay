var userdb = require('dirty')('./data/user.db');
var uuid = require('node-uuid');
var _ = require('./underscore');

// exports.start = function(fn) {
//     userdb.on('load', function(){
//         userdb.findNick = function(nick) {
//             var result;
//             userdb.forEach(function(key, nickRec){
//                 if (nickRec.nick === nick) {
//                     result = {key: key, value: nickRec};
//                     return false
//                 }
//             })
//             return result;
//         };
//         
//         userdb.addNick = function(newNickName) {
//             var rec = userdb.findNick(newNickName);
//             if (rec) return rec;
//             rec = {nick: newNickName, lastSeen: (new Date()).getTime(), timeSpent: 0, nickId: uuid()};
//             var key = uuid();
//             userdb.set(key, rec)
//             return {key: key, value: rec};
//         };
//         
//         userdb.linkedNicks = function(nick) {
//             var rec = userdb.findNick(nick);
//             var result = [];
//             userdb.forEach(function(key, nickRec){
//                 if (nickRec.nickId === rec.value.nickId) {
//                     result.push({key: key, value: nickRec});
//                 }
//             })
//             return result;
//         };
//         
//         userdb.linkNick = function(nick, sourceNick) {
//             var n1 = userdb.linkedNicks(nick);
//             if (n1.length != 1) return false;
//             n1 = n1[0];
//             var n2 = userdb.findNick(sourceNick);
//             n1.value.nickId = n2.value.nickId;
//             userdb.set(n1.key, n1.value);
//             return true;
//         };
//         fn(userdb);
//     })
// };
//     
            // if (!cb && typeof(prevNickName) === 'function') {
            //     cb = prevNickName;
            //     prevNickName = cb;
            // };
            // var existingNick = Nick.find({nick: {$eq: newNickName}}).first()(function(err, key, value){
                // if (existingNick) {
                //     cb(null, existingNick);
                // } else {
                    // var newNick = Nick.new({nick: newNickName, nick_id: uuid()});
                    // newNick.save(function(err){
                    //     cb(err, newNick);
                    // });
                // };
            // });
                // var prevNick = Nick.find({nick: {$eq: newNickName}}).first();
                // if (prevNickName && !prevNick) {
                //     cb("unknown nickname " + prevNickName, null);
                // } else {
                //     
                // }

// exports.start(function(users){
    // users.addNick("thenu");
    // users.set("A67E06E7-4036-4246-9071-C49AB0063CE2", "thenu")
    // users.forEach(function(k,v){
    //     console.log(k);
    //     console.log(users.get(k));
    // })
// })
    // console.log(users.addNick('thenu'));
    // console.log('started');
    // console.log(users.addNick('magic'));
    // console.log(users.addNick('mountain'));
    // console.log(users.addNick('mushroom'));
    // console.log(users.linkedNicks('thenu'));
    // console.log(users.linkNick('mountain', 'mushroom'));
    // console.log(users.linkNick('thenu', 'magic'));
    // console.log(users.linkNick('mountain', 'magic'));
    // console.log('tehntuehntuenst')
    // _(['thenu', 'mountain', 'magic', 'mushroom']).each(function(n){
    //     console.log(users.linkedNicks(n));
    // })
    // users.on('drain', function(){})
    // 
    // })
     // var nn = nick.new({nick: "thenu", nick_id: Math.floor(Math.random()*1000)});
    // nn.save(function(err){
    //     console.log(err);
    //     console.log(nn);
    // })
    // nick.find({nick: {$eq: "thenu"}}).all(function(value){
    //     console.log("find");
    //     console.log(arguments);  
    // })
    
    // nick.addNick("thenu", function(err, item){
    //       console.log("add");
    //       console.log(err, item);
    //       nick.find({nick: {$eq: "thenu"}}).all(function(value){
    //           console.log("thenu is");
    //           console.log(arguments);  
    //       })
    //       nick.find({nick: {$eq: "thent"}}).all(function(value){
    //           console.log("thent is");
    //           console.log(arguments);  
    //       })
          
          
    // })
    // });

