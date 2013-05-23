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
  constructor: ({@emitter}) ->
    super
    @commands = {a: @command}
    @command._help = "search anidb for the anime that matches the terms. !a <name> lists all the matches, or the show if there is only one match. !a x <name> gives you the xth match."
  regexes: [/http:\/\/anidb\.net\/perl-bin\/animedb.pl\?(?:.*)aid=(\d+)(?:.*)/]

  on_match: (from, match) =>
    @get_info match[1], ({titles: [{title: t_list}], description}) =>
      english_title = @get_english_title(t_list)
      title_string = _(t_list).find(({type}) => type is 'main')['#']
      title_string += " (#{english_title})" if english_title
      @emitter "That anidb link is #{title_string} #{description}"

  get_english_title: (t_list, extract) =>
    match = (lang_name, type_name) =>
      _(t_list).find ({lang, type}) => lang is lang_name and type is type_name
    english_node = match("en", "official") or
      match("en", "synonym") or
      match("x-jat", "synonym")
    english_node?['#']

  get_english_title_anidb: (t_list) =>
    get_english_title _(t_list).map ({"xml:lang": lang, type}) => {lang: lang, type: type}

  get_info: (aid, cb) =>
    url = "http://api.anidb.net:9001/httpapi?#{param_string}&aid=#{aid}"
    _.requestXmlAsJson {uri: url, cache: aid}, (err, {anime}) ->
      cb(anime) unless err or !anime

  command: (from, tokens, cb) =>
    @parse_query tokens, (error, number, search_tokens) =>
      return cb("a! <anime name>") if error
      query_fn = if @is_inexact_query(search_tokens) then @inexact else @exact
      query_fn search_tokens, (animes) =>
        animes = [animes] unless _(animes).isArray()
        return cb("No Results") if @no_data_in_range(animes, number)
        if animes.length is 1
          @display_info animes[0], cb
        else if number
          @display_info animes[number-1], cb
        else
          @display_options search_tokens, animes, cb

  is_inexact_query: (search_tokens) =>
    search_tokens[0] is '~' and search_tokens.length > 1

  no_data_in_range: ({length}, number) =>
    length is 0 or (number and number > length)

  parse_query: (tokens, cb) =>
    [number, search_tokens] = @split_query(tokens)
    if _(search_tokens).isEmpty()
      cb(true)
    else
      cb(null, number, search_tokens)

  split_query: (tokens) =>
    if /^\d+$/.test(_(tokens).head())
      [_(tokens).head(), _(tokens).tail()]
    else
      [null, tokens]

  url: (search_for) =>
    param_string = _({task: "search", query: search_for}).stringify()
    "http://anisearch.outrance.pl/?#{param_string}"

  ani_search: (search_for, cb) =>
    _.requestXmlAsJson {uri: @url(search_for)}, (error, data) =>
      if error
        console.error "anidb search error #{error}"
      else
        cb data

  inexact: (tokens, cb) =>
    tokens = tokens[1..] if tokens[0] is '~'
    {true: long_tokens, false: short_tokens} =
      _(tokens).groupBy ({length}) => length >= 4
    search_for = _(_(long_tokens).map (t) -> "+#{t}").
      concat(_(short_tokens).map (t) -> "%#{t}%").join(" ")
    @ani_search search_for, ({animetitles: {anime}}) =>
      cb anime if anime

  exact: (tokens, cb) =>
    @ani_search "\\#{tokens.join(" ")}", ({animetitles: {anime}}) =>
      if anime
        cb anime
      else
        @inexact tokens, cb

  display_info: ({title: t_list, aid}, cb) =>
    name = _(t_list).find(({type}) => type is 'main')['#']
    exact_name = _(t_list).find(({exact}) => exact)?['#'] or name
    english_name = @get_english_title(t_list) or name
    msg = name + (if name is exact_name then "" else " officially known as #{exact_name}")
    msg += " (#{english_name})" unless english_name is exact_name
    cb "#{msg}. http://anidb.net/perl-bin/animedb.pl?show=anime&aid=#{aid}"
    @get_info aid, ({description}) =>
      cb description

  display_options: (search_tokens, animes, cb) =>
    list_str = _(animes).chain().
      first(7).
      numbered().
      map(([i, {title: t_list}]) => "#{i}. #{_(t_list).find(({exact}) => exact)['#']}").
      sentence().
      value()
    cb "#{search_tokens.join(' ')} could be #{list_str} #{if animes.length > 7 then 'or others.' else '.'}"

module.exports = Anidb
