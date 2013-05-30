start
  = segments:span_segment+ "ago" {
      return segments.map(function(seg){
         var letter = /month/.test(seg[1]) ? "M" : seg[1][0]
         return [seg[0], letter]
      });
  }
  / "now" {
	return [[0, 's']]
  }

plural
  = "years" / "months" / "weeks" / "days" / "hours" / "minutes" / "mins" / "seconds" / "secs"

singular
  = "year" / "month" / "week" / "day" / "hour" / "minute" / "min" / "second" / "sec"

span_segment
  = segment:(singular_span / plural_span) " "+ { return segment}

singular_span
  = "1" " "+ t:singular { return [1, t]}

plural_span
 = x:integer " "+ t:plural {return [x, t]}

integer "integer"
  = digit:[1-9] digits:[0-9]* { return parseInt(digit + digits.join(""), 10); }