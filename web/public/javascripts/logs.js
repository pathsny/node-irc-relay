$( init );

function init() {
    var url = document.location.toString();
    var match = /.*#(.*)/.exec(url);
    if (match) {
        var time = new Date();
        $.get("/" + match[1] + ".log", function(data){
            console.log(data);
        });
        console.error("time", new Date() - time)
    };
}