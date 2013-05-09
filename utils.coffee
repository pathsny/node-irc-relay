_ = global._ = require("underscore")
_.mixin require("underscore.date")
req = require("request")
fs = require("fs")
qs = require("querystring")
sanitizer = require("sanitizer")
zlib = require("zlib")
xmljs = require("xml2js")
xmlParser = new xmljs.Parser(mergeAttrs: true, charkey: '#')
_.date().customize relativeTime:
  future: "in %s"
  past: "%s ago"
  s: "less than a minute"
  m: "about a minute"
  mm: "%d minutes"
  h: "about an hour"
  hh: "about %d hours"
  d: "a day"
  dd: "%d days"
  M: "about a month"
  MM: "%d months"
  y: "about a year"
  yy: "%d years"

_.mixin
  sentence: (words) ->
    return words  if not words or words.length is 1
    beginning = _(words).first(words.length - 1)
    beginning.join(", ") + " and " + _(words).last()

  capitalize: (word) ->
    word.charAt(0).toUpperCase() + word.slice(1)

  rand: (list) ->
    list[Math.floor(Math.random() * list.length)]

  zipWithIndex: (list) ->
    _.zip list, _.range(list.length)

  articleize: (word) ->
    ((if /^[aeiou]/i.test(word) then "an" else "a")) + " " + word

  stringify: (obj) ->
    qs.stringify(obj).replace /'/g, "%27"

  invoke_: (obj, method) ->
    args = _(arguments).slice(2)
    _.map obj, (value) ->
      value = _(value)
      ((if method then value[method] else value)).apply value, args


  html_as_text: (text) ->
    sanitizer.unescapeEntities text.replace(/<[^>]*>/g, "")

  partitionAt: (list, iterator, context) ->
    i = 0

    while i < list.length
      break  unless iterator.call(context, list[i])
      i++
    [list.slice(0, i), list.slice(i)]

  numbered: (list) ->
    _(1).chain().range(list.length + 1).zip(list).value()

  second: (list) -> list[1]

  gmtDate: (date) ->
    date = date.date  if date.date
    yyyy = "" + date.getUTCFullYear()
    mm = "" + date.getUTCMonth()
    mm = "0" + mm  if mm.length is 1
    dd = "" + date.getUTCDate()
    dd = "00" + dd  if dd.length is 1
    yyyy + "_" + mm + "_" + dd

  _streamToString: (stream, cb) ->
    str = ""
    stream.on "data", (c) ->
      str += c.toString()

    stream.on "end", ->
      cb str


  _compressedReq: (options, cb) ->
    r = req(_(options).extend(headers:
      "Accept-Encoding": "gzip, deflate"
    ))
    r.on "response", (response) ->
      headers = response.headers["content-encoding"]
      stream = (if (headers and (headers.search("gzip") isnt -1 or headers.search("deflate") isnt -1)) then r.pipe(zlib.createUnzip()) else r)
      _._streamToString stream, (data) ->
        cb `undefined`, response, data


    r.on "error", (err) ->
      cb err


  inSlicesOf: (items, size) ->
    slices = Math.ceil(items.length / size)
    _(1).range(slices + 1).map (n) ->
      start = (n - 1) * size
      items.slice start, start + size


  requestXmlAsJson: (options, cb) ->
    @request options, (error, response, body) ->
      if error or response.statusCode isnt 200
        cb error
      else
        xmlParser.parseString body, (err, result) ->
          cb err, result



  request: (options, cb) ->
    cache = undefined
    cache = "#{__dirname}/data/cache/" + options.cache  if options.cache
    handle_resp = (error, response, body) ->
      if not error and options.cache
        encoding = options.encoding or "utf8"
        cacheData = JSON.stringify([
          httpVersion: response.httpVersion
          headers: response.headers
          statusCode: response.statusCode
        , body])
        fs.writeFile cache, cacheData
      cb error, response, body

    http_req = ->
      _._compressedReq options, (error, response, body) ->
        handle_resp error, response, body


    return http_req()  unless cache
    fs.stat cache, (err, stats) ->
      if not err and stats.mtime >= _.now().subtract(w: 1).date
        fs.readFile cache, (err, data) ->
          unless err
            try
              result = JSON.parse(data)
              cb `undefined`, result[0], result[1]

      else
        http_req()


  displayChatMsg: (from, msg) ->
    actionMatch = /^\u0001ACTION(.*)\u0001$/.exec(msg)
    if actionMatch
      "*" + from + actionMatch[1]
    else
      "<" + from + "> " + msg

  automated: (msg) ->
    /\u000311.•\u000310\u0002«\u0002\u000311WB\u000310 \u0002\(\u000f\u0002.+\u000310\)\u0002 \u000311WB\u000310\u0002»\u0002\u000311•. \u000310\u0002-\u000f \u001f/.test msg

  invoke_: (list, functionName) ->
    args = _(arguments).slice(2)
    _(list).map ((item) ->
      this[functionName].apply this, _([item]).concat(args)
    ), this

module.exports = _
