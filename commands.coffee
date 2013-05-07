_ = require("underscore")
require "./utils"
anidb = require("./anidb")
Email = require("./email")
gtalk = require("./gtalk").gtalk

class Commands
  constructor: (@users, @settings) ->

module.exports = Commands

directedMessage = (from, tokens, cb, users, success) ->
  to = _(tokens).head()
  msg = _(tokens).tail().join(" ")
  unless to and msg
    cb "Message not understood"
  else unless users.get(to)
    cb to + " is not known"
  else
    success to,
      from: from
      msg: msg
      time: Date.now()

    cb from + ": Message Noted"

commands = fs.readdirSync("./Commands")
_(commands).
chain().
select((f) -> f.match(/.*\.coffee/)).
each (f) ->
  console.log(f)
  commandData = require("./Commands/#{f}")
  name = commandData['name']
  Commands::[name] = commandData['command']
  Commands::[name]._help = commandData['help']

command_definitions =
  g:
    command: (from, tokens, cb) ->
      if /^\d+/.test(_(tokens).head())
        number = _(tokens).head()
        msg = _(tokens).tail().join(" ")
      else
        number = "1"
        msg = tokens.join(" ")
      requestNumber = Math.floor((Number(number) - 1) / 4) * 4
      resultIndex = Number(number) - requestNumber - 1
      url = "https://ajax.googleapis.com/ajax/services/search/web?" + _(
        q: msg
        v: "1.0"
        key: @settings["google_key"]
        start: requestNumber
      ).stringify()
      _.request
        uri: url
      , (error, response, body) ->
        if not error and response.statusCode is 200
          responseJson = JSON.parse(body)
          if responseJson.responseStatus isnt 200
            cb "google error '" + responseJson.responseDetails + "' "
            return
          res = responseJson.responseData
          results = res.results
          resultIndex = results.length - 1  unless results[resultIndex]
          if resultIndex is -1
            cb "no results! "
            return
          result = results[resultIndex]
          resNumber = res.cursor.currentPageIndex * 4 + resultIndex + 1
          cb result.titleNoFormatting + "   " + result.unescapedUrl + "  " + _(result.content).html_as_text() + " ... Result " + resNumber + " out of " + res.cursor.estimatedResultCount


    _help: "search google for the terms you're looking for. !g <terms> for the first result. !g x <terms> for the xth result"

  m:
    command: (from, tokens, cb) ->
      query = tokens.join(" ").replace(/^\s+|\s+$/g, "")
      url = "http://tinysong.com/b/" + encodeURIComponent(query) + "?" + _(
        format: "json"
        key: @settings["tinysong_key"]
      ).stringify()
      _.request
        uri: url
      , (error, response, body) ->
        if not error and response.statusCode is 200
          responseJson = JSON.parse(body)
          unless responseJson.Url is `undefined`
            cb "Listen to " + responseJson.ArtistName + " - " + responseJson.SongName + " at " + responseJson.Url
          else
            cb "No song found for: " + query


    _help: "searches tinysong and provides a url to grooveshark to listen to the song"

  a:
    command: (from, tokens, cb) ->
      search_tokens = undefined
      if /^\d+$/.test(_(tokens).head())
        number = _(tokens).head()
        search_tokens = _(tokens).tail()
      else
        number = `undefined`
        search_tokens = tokens
      if search_tokens.length is 0
        cb "a! <anime name>"
        return
      exact_msg = "\\" + search_tokens.join(" ")
      long_tokens = _(search_tokens).filter((token) ->
        token.length >= 4
      )
      short_tokens = _(search_tokens).filter((token) ->
        token.length < 4
      )
      msg = _(long_tokens).chain().map((token) ->
        "+" + token
      ).concat(_(short_tokens).map((token) ->
        "%" + token + "%"
      )).value().join(" ")
      anidb_info = (anime) ->
        englishNode = _(anime.title).find((t) ->
          t.lang is "en" and t.type is "official"
        ) or _(anime.title).find((t) ->
          t.lang is "en" and t.type is "syn"
        ) or _(anime.title).find((t) ->
          t.lang is "x-jat" and t.type is "syn"
        )
        mainNode = _(anime.title).find((t) ->
          t.type is "main"
        )
        exactNode = _(anime.title).find((t) ->
          t.exact
        )
        msg = mainNode["#"]
        msg = exactNode["#"] + " offically known as " + msg  unless exactNode is mainNode
        msg += " (" + englishNode["#"] + ")"  if englishNode and englishNode isnt exactNode
        cb msg + ". http://anidb.net/perl-bin/animedb.pl?show=anime&aid=" + anime["aid"]
        anidb.getInfo anime["aid"], (data) ->
          cb data.splitDescription


      parse_results = (animes) ->
        animes = [animes]  unless _(animes).isArray()
        size = animes.length
        extra_msg = (if size > 7 then " or others." else ".")
        if size is 0
          cb "No Results"
        else if size is 1
          anidb_info animes[0]
        else if number and number <= size
          anidb_info animes[number - 1]
        else
          cb _(search_tokens).join(" ") + " could be " + _(animes).chain().first(7).numbered().map((ttl) ->
            ttl[0] + ". " + _(ttl[1].title).find((t) ->
              t.exact
            )["#"]
          ).join(", ").value() + extra_msg

      inexactMatch = ->
        url = "http://anisearch.outrance.pl/?" + _(
          task: "search"
          query: msg
        ).stringify()
        _.requestXmlAsJson
          uri: url
        , (error, data) ->
          if error
            console.error error
          else
            animes = data["anime"]
            parse_results animes  if animes


      exact_Match = ->
        url = "http://anisearch.outrance.pl/?" + _(
          task: "search"
          query: exact_msg
        ).stringify()
        _.requestXmlAsJson
          uri: url
        , (error, data) ->
          if error
            console.error error
          else
            animes = data["anime"]
            if animes
              parse_results animes
            else
              inexactMatch()


      if /^~$/.test(search_tokens[0]) and search_tokens.length > 1
        inexactMatch()
      else
        exact_Match()

    _help: "search anidb for the anime that matches the terms. !a <name> lists all the matches, or the show if there is only one match. !a x <name> gives you the xth match."

  tell:
    command: (from, tokens, cb) ->
      users = @users
      directedMessage from, tokens, cb, users, (nick, data) ->
        users.addTell nick, data


    _help: "publically passes a message to a user whenever he/she next speaks. usage: !tell <user> <message>"

  msg:
    command: (from, tokens, cb) ->
      users = @users
      directedMessage from, tokens, cb, users, (nick, data) ->
        users.addMsg nick, data


    _help: "stores a message in a user's message box for him/her to retrieve later at leisure. Ideal for links/images that cannot be opened on phones"

  seen:
    command: (from, tokens, cb) ->
      person = _(tokens).head()
      unless person
        cb "!seen needs a person to have been seen"
      else unless @users.get(person)
        cb person + " is not known"
      else
        aliases = @users.aliases(person)
        online_aliases = _(aliases).filter((item) ->
          item.val.status is "online"
        )
        if online_aliases.length > 0
          msg = person + " is online"
          msg += " as " + _(online_aliases).chain().pluck("key").sentence().value()  if online_aliases.length > 1 or _(online_aliases).first().key isnt person
        else
          lastOnline = _(aliases).max((item) ->
            item.val.lastSeen
          )
          msg = person + " was last seen online"
          msg += " as " + lastOnline.key  if person isnt lastOnline.key
          msg += " " + _.date(lastOnline.val.lastSeen).fromNow()
          msg += " and quit saying " + lastOnline.val.quitMsg  if lastOnline.val.quitMsg
        lastSpoke = _(aliases).max((item) ->
          return 0  unless item.val.lastMessage
          item.val.lastMessage.time
        )
        if lastSpoke and lastSpoke.val.lastMessage
          lastMessage = lastSpoke.val.lastMessage
          msg += " and " + _.date(lastMessage.time).fromNow() + " I saw "
          msg += _.displayChatMsg(lastSpoke.key, lastMessage.msg)
        cb msg

    _help: "let's you know when a user was last seen online and last spoke in the channel. Also should end up triggering his/her nick alert ;) "

  nick:
    command: (from, tokens, cb) ->
      user = _(tokens).head()
      unless user
        cb "it's nick! <username> "
      else
        aliases = @users.aliasedNicks(user)
        unless aliases
          cb user + " is not known"
        else
          if aliases.length is 1
            cb user + " has only one known nick"
          else
            cb "known nicks of " + user + " are " + _(aliases).sentence()

    _help: "lists all the nicknames a user has used in the past"

  link:
    command: (from, tokens, cb) ->
      nick = _(tokens).head()
      group = _(tokens).chain().tail().head().value()
      unless nick and group
        cb "link <nick> <group>"
      else
        result = @users.link(nick, group)
        if result
          cb nick + " has been linked with " + group
        else
          cb "link only known UNLINKED nicks with other nicks"

    _help: "links a nickname to any nickname from an existing set of nicknames. You can only link an unlinked nickname to other nicknames. usage !link nick1 nick2"

  unlink:
    command: (from, tokens, cb) ->
      nick = _(tokens).head()
      group = _(tokens).chain().tail().head().value()
      unless nick and group
        cb "unlink <nick> <group>"
      else
        result = @users.unlink(nick, group)
        if result
          cb nick + " has been unlinked from " + group
        else
          cb "unlink linked nicks"

    _help: "unlink a nickname from an existing group of nicknames"

  alert:
    command: (from, tokens, cb) ->
      nick = _(tokens).head()
      user = @users.get(nick)
      if not nick or tokens.length <= 1
        cb "alert <nick> message"
        return
      else unless user
        cb "alert requires the nick of a valid user in the channel"
        return
      email_address = @users.getEmailAddress(nick)
      message = "<" + from + "> " + _(tokens).tail().join(" ")
      unless email_address
        if gtalk.tryAlert(nick, message)
          cb "sent a gtalk alert to " + nick
        else
          cb nick + " has not configured any alert options"
      else
        gtalk.tryActiveAlert nick, message, _((result) ->
          if result
            cb "sent a gtalk alert to " + nick
            return
          unless @_email
            @_email = new Email(
              user: @settings.gmail.user
              pass: @settings.gmail.password
              clientName: "Misaka Alerts"
            )
          @_email.send
            text: message
            to: nick + " <" + email_address + ">"
            subject: "Alert Email from " + from
          , (err) ->
            if err
              cb "sorry an error occured"
            else
              cb "sent an email alert to " + nick

        ).bind(this)

    _help: "send an alert to a member of the group who has added their email address to me. alert <nick> message"

  count:
    command: (from, tokens, cb) ->
      number = Number(_(tokens).first() or 5)
      if _(number).isFinite()
        if number > 7
          cb "Please be reasonable. I do not have enought sticks and stones to count down from " + number
        else if number < 0
          cb "I can only count from numbers greater than 0"
        else unless Commands::count._countLock
          Commands::count._countLock = true
          count = (i) ->
            cb (if i > 0 then i else "GO!"), true
            if i > 0
              setTimeout (->
                count i - 1
              ), 1000
            else
              Commands::count._countLock = false

          count number
      else
        cb "I need a valid number to countdown from"

    _countLock: false
    _help: "counts down from n to zero. usage !count n"

  twitter:
    command: (from, tokens, cb) ->
      self = this
      follow = (user, twitter_name) ->
        unless twitter_name
          cb "Mention which twitter user to follow. usage !twitter add <twitter id> to start following this id."
          return
        _.request
          uri: "http://api.twitter.com/1/users/lookup.json?screen_name=" + twitter_name
        , (error, response, body) ->
          user_data = _(JSON.parse(body)).find((data) ->
            data.screen_name is twitter_name
          )
          if user_data
            self.users.setTwitterAccount from, user_data["id"]
            self.users.emit "twitter follows changed"
            msg = "following user called " + twitter_name + " with id " + user_data["id"]
            cb msg
            if user_data["status"] and user_data["status"]["text"]
              tweet = user_data["status"]["text"].split(/\r/)
              cb "whose last tweet was " + tweet[0]
              _(tweet).chain().tail().each (part) ->
                cb part

          else
            cb "cannot find the user called " + twitter_name


      unfollow = (user) ->
        self.users.clearTwitterAccount from
        self.users.emit "twitter follows changed"

      switch _(tokens).head()
        when "add"
          follow from, tokens[1]
        when "remove"
          unfollow from
        else
          cb "usage !twitter add <twitter id> to start following this id. !twitter remove <twitter id> to stop following this id"

    _help: "add or remove a twitter account to follow. Usage !twitter add <twitter id> to start following this id. !twitter remove <twitter id> to stop following this id"

Commands::commands = Commands::help
_(command_definitions).chain().keys().each (commandName) ->
  command_definition = command_definitions[commandName]
  Commands::[commandName] = command_definition["command"]
  Commands::[commandName]._help = command_definition["_help"]

Commands::listeners = (respond) ->
  self = this
  matchers = require("./url_matchers").matchers

  # convey messages
  [(from, message) ->
    return  if _(message).automated()
    rec = self.users.get(from)
    if rec
      tells = self.users.getTells(from)
      if tells.length > 0
        _(tells).forEach (item) ->
          msg = from + ": " + item.from + " said '" + item.msg + "'"
          msg += " " + _.date(item.time).fromNow()  if item.time
          respond "tell", msg

        self.users.clearTells from
  , (from, message) ->
    return  if _(message).automated()
    respond "tell", from + ": There are new Messages for you. Msg me to retrieve them"  if self.users.unSetNewMsgFlag(from)
  , (from, message) ->
    _(matchers).chain().keys().detect (type) ->
      matching_regex = _(matchers[type].regexes).detect((regex) ->
        regex.test message
      )
      if matching_regex
        matchers[type].responder from, message, matching_regex.exec(message), (msg) ->
          respond type + "_metadata", msg

        true

  ]
