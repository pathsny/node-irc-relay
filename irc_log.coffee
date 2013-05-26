fs = require("fs")
_ = require("underscore")
require "./utils"

class Logger
  constructor: ->
    @_msgs = []
    @_flushing = false

  _writestream: (gmtDate) ->
    return @_ws  if @_gmtDate and @_gmtDate is gmtDate
    @_ws.end()  if @_ws
    @_gmtDate = gmtDate
    @_ws = fs.createWriteStream("#{__dirname}/data/irclogs/" + gmtDate + ".log",
      encoding: "utf-8"
      flags: "a"
    )
    @_ws

  log: (msg) =>
    @_msgs.push [_.now(), msg]
    @_maybeFlush()

  _maybeFlush: =>
    return if @_flushing
    @_flushing = true
    date = _(@_msgs[0][0]).gmtDate()
    ws = @_writestream(date)
    msgPartition = _(@_msgs).partitionAt((msg) ->
      _(msg[0]).gmtDate() is date
    )
    data = _(msgPartition).chain().first().map((msg) ->
      JSON.stringify([msg[0].date.getTime(), msg[1]]) + "\n"
    ).value().join("")
    @_msgs = msgPartition[1]
    ws.write data, =>
      @_flushing = false
      process.nextTick @_maybeFlush unless _(@_msgs).isEmpty()

exports.Logger = (textEmittor) ->
  logger = new Logger
  textEmittor.on "text", logger.log
  logger

