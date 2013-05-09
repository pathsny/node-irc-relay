#provides a command to query anidb and a url matcher to identify anidb urls
_ = require('../utils')
RegexUrlMatcher = require("#{__dirname}/base/regex_url_matcher")

param_string = _({
  request: 'anime',
  client: 'misakatron',
  clientver: '1',
  protover: '1'
}).stringify()

class Anidb extends RegexUrlMatcher
  constructor: (users, settings, @emitter) ->
    super

  regexes: [/http:\/\/anidb\.net\/perl-bin\/animedb.pl\?(?:.*)aid=(\d+)(?:.*)/]

  on_match: (from, match) =>
    @get_info match[1], ({titles: [{title: t_list}], description}) =>
      english_title = @get_english_title(t_list)
      title_string = _(t_list).find(({type}) => type is 'main')['#']
      title_string += " (#{english_title})" if english_title
      @emitter "That anidb link is #{title_string} #{@split_description(description)}"

  get_english_title: (t_list) =>
    match = (lang_name, type_name) =>
      _(t_list).find ({"xml:lang": lang, type}) => lang is lang_name and type is type_name
    english_node = match("en", "official") or
      match("en", "synonym") or
      match("x-jat", "synonym")
    english_node?['#']

  get_info: (aid, cb) =>
    url = "http://api.anidb.net:9001/httpapi?#{param_string}&aid=#{aid}"
    _.requestXmlAsJson {uri: url, cache: aid}, (err, {anime}) ->
      cb(anime) unless err

  split_description: (description) =>
    return "no description provided" unless description
    _(description).chain().
    invoke("split", "\n").
    first().
    invoke_("inSlicesOf", 400).
    flatten().
    join("\n").
    value()

module.exports = Anidb