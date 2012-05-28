var users = {}

var localStream;

var startSocket = function() {
    var socket = io.connect('/');

    socket.on('user connected', function(name){
    });
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
      $('#container').append("<div id='video_" + sid +  "'/>");
      $('#video_'+sid).append('<span>'+name+'</span>');
      $('#video_'+sid).append("<video autoplay='autoplay'/>");
      var video = $('#video_'+sid + ' video')[0]
      var url = webkitURL.createObjectURL(event.stream);
      video.style.opacity = 1;
      video.src = url;
    }
    pc.onremovestream = function(event) {
      $('#video_'+sid).html('');
    };
    var oldClose = pc.close
    pc.close = function() {
        $('#video_'+sid).html('');
        oldClose.call(pc);
    }
    pc.addStream(localStream);
    return pc;
}

$(document).ready(getUserMedia);



