_ = require('../utils')

class Count
  constructor: (users, settings, emitter) ->
    @commands = {count: @command}
    @command._help = "counts down from n to zero. usage !count n"
    @_lock = false

  command: (from, tokens, cb) =>
    [number, error] = @parse tokens
    if error
      cb error
      return
    unless @_lock
      @_lock = true
      @count number, cb, => @_lock = false

  count: (number, cb, on_done) =>
    cb (if number > 0 then number else "GO!"), true
    if number > 0
      setTimeout (=> @count(number-1, cb, on_done)), 1000
    else
      on_done()

  parse: (tokens) =>
    number = Number(_(tokens).first() or 5)
    return [number, "I need a valid number to countdown from"] unless _(number).isFinite()
    return [number, "Please be reasonable. I do not have enought sticks and stones to count down from #{number}"] if number > 7
    return [number, "I can only count from numbers greater than 0"] if number < 0
    [number]

module.exports = Count

