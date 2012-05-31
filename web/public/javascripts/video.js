var users = {}

var localStream;

// $('#drop_video')

var inGroupsOf = function(list, count) {
    return list.reduce(function(acc, item){
        if (acc.length === 0 || acc[acc.length - 1].length === count) {
            acc.push([item]);
        } else {
            acc[acc.length-1].push(item);
        }
        return acc;
    }, []);
}

var Videos = (function() {
        var tmpl;
        var template = function () {
            if (tmpl) return tmpl;
            tmpl = $("#VideoTemplate");
            return tmpl;
        }
        var video_list = [];
        var container_container = $('#container_container');
        var container = $('#peer_container');
        var dummy = function(size) {
            return '<div class="span' + size + '"></div>'
        };
        
        var render_row = function() {
            var row = $('<div class="row-fluid"/>').appendTo(container);
            $(arguments).each(function(i, item){
                if (!item.length) {
                    row.append(dummy(item))
                } else {
                    var video = item[1][1];
                    row.append(video);
                    video.removeClass();
                    video.addClass('span' + item[0]);
                }
            })
        }
        
        var render = function() {
            container.html('');
            if (video_list.length === 1) {
                render_row(4, [4, video_list[0]], 4);
            } else if (video_list.length === 2) {
                render_row(2, [4, video_list[0]], [4, video_list[1]], 2);
            } else {
                var video_groups = inGroupsOf(video_list, 3);
                $(video_groups).each(function(i, group){
                    if (group.length === 3) {
                        render_row([4, group[0]], [4, group[1]], [4, group[2]]);
                    } else if (group.length === 2){
                        render_row(1, [4, group[0], 2, [4, group[1]], 1]);
                    } else if (group.length === 1) {
                        render_row(4, [4, group[0], 4]);
                    }
                })
            }
        };
        
    return {
        add: function(sid, name, stream) {
            video_list.push([sid, template().tmpl({sid: sid, nick: name.split(' ')[0], src: webkitURL.createObjectURL(stream)})]);
            render();
        },
        remove: function(sid) {
            video_list = $.grep(video_list, function(video_item) {
                return video_item[0] != sid;
            });
            render(); 
        }
    }
    
})();

 var startSocket = function() {
    var socket = io.connect('/');
    
    socket.on('connect', function(){
        $('#chatLine').attr('disabled', false);
    });
    
    (function(chatLine){
        chatLine.keypress(function(e){
            if(e.which == 13){
                if (chatLine.val().trim() !== '') {
                    socket.emit('chat_message', chatLine.val());
                    chatLine.val('');
                }  
            }
        });
    })($('#chatLine'));

    socket.on('user disconnected', function(name){
        if (users[name]) {
            users[name].close();
            delete users[name];            
        }
    });
    
    socket.on('signalling message',function(data){
        if (!users[data.user]) {
            users[data.user] = createPeerConnection(data.user, createSignallingCallback(data.user));
        }
        users[data.user].processSignalingMessage(data.data)
    });
    
    var createSignallingCallback = function(name) {
        return function(message) {
            socket.emit('signalling message', {
                user: name,
                data: message
            });
        }
    }

    socket.on('existing users', function(names){
        $(names).each(function(i, name){
            users[name] = createPeerConnection(name, createSignallingCallback(name));
        })
    });
    
    var chatArea = $('#chatArea');
    socket.on('text', function(m){
        chatArea.append('<br/>');
        var newElement = $('<span/>').text('['+ moment().format('HH:MM') +']'+m);
        chatArea.append(newElement);
        newElement[0].scrollIntoView();
    })
}

onUserMediaSuccess = function(stream) {
  console.log("User has granted access to local media.");
  var url = webkitURL.createObjectURL(stream);
  var localVideo = $('#localVideo')[0];
  localVideo.style.opacity = 1;
  localVideo.src = url;
  localStream = stream;
  startSocket();
}

var getUserMedia = function() {
    try {
        navigator.webkitGetUserMedia({audio:true, video:true}, onUserMediaSuccess,
            onUserMediaError);
            console.log("Requested access to local media with new syntax.");
        } catch (e) {
            try {
                navigator.webkitGetUserMedia("video,audio", onUserMediaSuccess,
                onUserMediaError);
                console.log("Requested access to local media with old syntax.");
            } catch (e) {
                $('#container').html('you have to be using chrome. Open about:flags and enable mediastream');
            }
        }
    }

var onUserMediaError = function(error) { $('#container').html("Failed to get access to local media. Error code was " + error.code);}

createPeerConnection = function(name, onSignallingMessage) {
    var constructor = webkitDeprecatedPeerConnection || webkitPeerConnection;
    try {
        var pc = new constructor("STUN stun.l.google.com:19302", onSignallingMessage);
        console.log("Created " + constructor + " with config STUN stun.l.google.com:19302.");
    } catch (e) {
        $('#container').html("Cannot create PeerConnection object; Is the 'PeerConnection' flag enabled in about:flags?");
    }
    pc.onconnecting = function(m) {console.log("Session connecting with "+ name, m);};
    pc.onopen = function(m){ console.log('session opened with '+ name, m)}
    var sid = name.replace(/[^A-Za-z0-9]/g, '_')
    pc.onaddstream = onRemoteStreamAdded = function(event) {
      console.log("Remote stream added with ", name);
      Videos.add(sid, name, event.stream);
    }
    pc.onremovestream = function(event) {
        console.log("Remote stream removed with ", name);
        Videos.remove(sid);
    };
    var oldClose = pc.close
    pc.close = function() {
        Videos.remove(sid);
        oldClose.call(pc);
    }
    pc.addStream(localStream);
    return pc;
}

$(document).ready(getUserMedia);



