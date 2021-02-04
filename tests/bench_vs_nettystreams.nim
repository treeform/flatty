import benchy, flatty, streams, json, intsets, uri
import nettyrpc/nettystream

template bench(what: untyped) =
  var list: seq[type(what)]
  for i in 0 .. 1000:
    list.add(what)

  block:
    timeIt "flatty " & $type(what), 100:
      keep list.toFlatty().fromFlatty(type(list))

  block:
    timeIt "nettystream " & $type(what), 100:
      var ns = NettyStream()
      ns.write(list)
      ns.pos = 0
      var test: type(list)
      ns.read(test)
      keep test
let
  aNumber = 123.2123
  aSequence = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  aString = "https://irclogs.nim-lang.org/01-06-2020.html#20:54:23"
  anObject = parseUri(aString)

bench aNumber
bench aSequence
bench aString
bench anObject
