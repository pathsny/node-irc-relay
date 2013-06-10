start = topic:topic space+ msg:message {return  {topic: topic, msg:msg}}
   / nick:nick space+ msg:message {return {nicks: [nick], msg: msg}}
   / nicks:nick_list spaces msg:message { return {nicks: nicks, msg: msg}}

space = [ \t]
spaces = space*
alpha = [a-z_\-\\\[\]\{\}^`|]i
digits = [0-9]
alphanum = alpha / digits

nick_list = '<' spaces nick:nick spaces rest:commaAndNick* spaces '>' {
	return [nick].concat(rest)
}

commaAndNick = ',' spaces nick:nick {return nick}

nick = initial:alpha rest:alphanum* { return initial + rest.join('') }

message = m:.+ { return m.join('') }

topic = '#' rest:([^ ]+) { return rest.join('') }
