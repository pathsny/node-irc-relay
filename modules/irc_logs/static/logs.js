$( init );

var logTemplate;


_.mixin({
    gmtDate: function(date) {
        if (date.date) date = date.date;
        var yyyy = '' + date.getUTCFullYear();
        var mm = '' + date.getUTCMonth();
        if (mm.length === 1) mm = '0' + mm;
        var dd = '' + date.getUTCDate();
        if (dd.length === 1) dd = '00' + dd;
        return yyyy + "_" + mm + "_" + dd;
    },
    createGmtDate: function(str) {
        var dtm = /(.*)_(.*)_(.*)/.exec(str);
        var d = new Date();
        d.setUTCFullYear(dtm[1]);
        d.setUTCMonth(dtm[2]);
        d.setUTCDate(dtm[3]);
        return _.date(d);
    }
});

var topMarker = {};
var bottomMarker = {};

function displayAbove(hash) {
    if (topMarker.lock) return;
    topMarker.lock = true;
    topData(topMarker, 200, function(rows, newTopMarker){
        topMarker = newTopMarker;
        logTemplate.tmpl({Logs: rows}).prependTo("#content");
        if (hash) {
            setTimeout(function(){
                window.location.hash = "#1";
                window.location.hash = "#" + hash;
                topMarker.lock = undefined;
            },100)
        }
        else topMarker.lock = undefined;
    });
};

function displayBelow(hash) {
    if (bottomMarker.lock) return;

    bottomMarker.lock = true;
    bottomData(bottomMarker, 200, function(rows, newBottomMarker){
        bottomMarker = newBottomMarker;
        logTemplate.tmpl({Logs: rows}).appendTo("#content");
        bottomMarker.lock = undefined;
        if (hash) {
            setTimeout(function(){
                window.location.hash = "#1";
                window.location.hash = "#" + hash;
            },100)
        }
    });
};

function bottomData(marker, number, cb, rows) {
    if (number === 0) {
        cb(rows, marker);
        return;
    };
    getLog(marker.date, function(logs){
        if (!logs) {
            marker.location === "end";
            bottomData(marker, 0, cb, rows || []);
        } else {
            rlogs = logs.slice(marker.location+1, marker.location + number + 1);
            if (rlogs.length < number) {
                marker.date = _(_(marker.date).createGmtDate().add({d: 1})).gmtDate();
                marker.location = -1;
            }
            bottomData(marker, number - rlogs.length, cb, _(rows || []).concat(rlogs));
        }
    });
};

function topData(marker, number, cb, rows) {
    if (number === 0) {
        cb(rows, marker);
        return;
    };
    getLog(marker.date, function(logs){
        if (!logs) {
            marker.location === "end";
            topData(marker, 0, cb, rows || []);
        } else {
            var count = number;
            if (!marker.location) marker.location = logs.length;
            var n = marker.location - number;
            if (n < 0) {
                n = 0;
                count = marker.location;
            };
            rlogs = logs.slice(n, marker.location);
            marker.location = n;
            if (n === 0) {
                marker.date = _(_(marker.date).createGmtDate().subtract({d: 1})).gmtDate();
                marker.location = undefined;
            }
            topData(marker, number - count, cb, _(rlogs).concat(rows || []));
        }
    });
};

function init() {
    logTemplate = $("#logTemplate");
    var url = document.location.toString();
    var match = /.*#(.*)/.exec(url);
    var timestamp = match ? Number(match[1]) : new Date().getTime();
    var date = _(timestamp).chain().date().gmtDate().value();
    getLog(date,function(data){
      var location = _(data).sortedIndex({timestamp: timestamp}, function(log){
        return log.timestamp;
      });
      if (location >= data.length) location = data.length - 1
      topMarker = {date: date, location: location};
      bottomMarker = {date: date, location: location};
      logTemplate.tmpl({Logs: [data[location]]}).appendTo("#content");
      displayAbove();
      displayBelow(data[location].timestamp);
    });
}

var logs = {};


function getLog(dateString, cb) {
    if (dateString in logs) {
        cb(logs[dateString]);
    } else {
        $.get("/logs/" + dateString + ".log", function(data){
            logs[dateString] = _(data.split('\n')).chain().
            reject(function(l) {
                return l === ''
                }).
                map(function(l) {
                    var t = l.indexOf(',');
                    var timestamp = Number(l.slice(1,t));
                    return {
                        timestamp: timestamp,
                        date: _.date(timestamp).format("dddd, MMMM Do YYYY, hh:mm:ss"),
                        msg: l.slice(t+2,-2)
                    };
                }).value();
            cb(logs[dateString]);
        }).error(function(){console.log(arguments); cb(undefined)})
    }
};



    $(window).scroll(function(e){
        //scroll position
        if($(document).height() - $(window).scrollTop() - $(window).height() < 500){
            //wait for 500 milliseconds to confirm the user scroll action
            displayBelow()
        }

        if($(window).scrollTop() < 500){
            var oldHash = $('#content a').attr('name');
            //wait for 500 milliseconds to confirm the user scroll action
            displayAbove(oldHash)
        }
    });
