_ = require('../utils')

class Google
  constructor: ({settings: {modules: {google: {@key}}}}) ->
    @commands = {g: @command}
    @command._help = "search google for the terms you're looking for. !g <terms> for the first result. !g x <terms> for the xth result"

  command: (from, tokens, cb) =>
    [number, msg] = @extract_params(tokens)
    _.request {uri: @url(number, msg)}, (error, response, body) =>
      if error or response.statusCode isnt 200
        cb("google error")
      else
        cb @parse(number, JSON.parse(body))

  extract_params: (tokens) =>
    if /^\d+/.test(_(tokens).head())
      [Number(tokens[0]), tokens[1..].join(" ")]
    else
      [1, tokens.join(" ")]

  requestNumber: (n) =>
    Math.floor((n - 1) / 4) * 4

  url: (number, msg) =>
    params = {q: msg, v: "1.0", key: @key, start: @requestNumber(number)}
    "https://ajax.googleapis.com/ajax/services/search/web?" + _(params).stringify()

  parse: (number, respJson) =>
    return "google error '#{respJson.responseDetails}'" if respJson.responseStatus isnt 200
    resultIndex = number - @requestNumber(number) - 1
    {cursor, results} = respJson.responseData
    resultIndex = results.length - 1  unless results[resultIndex]
    return "no results!" if resultIndex is -1

    result = results[resultIndex]
    resNumber = cursor.currentPageIndex * 4 + resultIndex + 1
    return "#{result.titleNoFormatting} #{result.unescapedUrl} #{_(result.content).html_as_text()} ... Result #{resNumber} out of #{cursor.estimatedResultCount}"


module.exports = Google
