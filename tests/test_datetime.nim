import flatty, times

proc toFlatty(s: var string, x: DateTime) =
  s.toFlatty(x.toTime.toUnix)

proc fromFlatty(s: string, i: var int, x: var DateTime) =
  var
    unix: int64
  s.fromFlatty(i, unix)
  x = parse(
    "1970-01-01", "yyyy-MM-dd", utc()) + initTimeInterval(seconds = unix.int)

var date = parse("2000-01-01", "yyyy-MM-dd", utc())
echo date
echo date.toFlatty().fromFlatty(type(date))
assert date == date.toFlatty().fromFlatty(type(date))
