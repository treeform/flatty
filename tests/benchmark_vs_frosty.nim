import benchy, flatty, frosty, streams, json, intsets, uri

template bench(what: untyped) =
  let times = 1000
  block:
    timeIt "flatty " & $type(what), 100:
      for i in 0 .. times:
        keep what.toFlatty().fromFlatty(type(what))
    assert what.toFlatty().fromFlatty(type(what)) == what

  block:
    timeIt "vs frosty " & $type(what), 100:
      for i in 0 .. times:
        keep thaw[type(what)](what.freeze())
    assert thaw[type(what)](what.freeze()) == what
    #assert what.freeze().thaw[type(what)]() == what

proc makeJs(): JsonNode =
  var
    tJsA = newJArray()
    tJsO = newJObject()
    tJs = newJObject()

  tJsA.add newJString"pigs"
  tJsA.add newJString"horses"

  tJsO.add "toads", newJBool(true)
  tJsO.add "rats", newJString"yep"

  for k, v in {
    "empty": newJNull(),
    "goats": tJsA,
    "sheep": newJInt(11),
    "ducks": newJFloat(12.0),
    "dogs": newJString("woof"),
    "cats": newJBool(false),
    "frogs": tJsO,
  }.items:
    tJs[k] = v
  result = tJs

var
  tJs {.compileTime.} = makeJs()
  tIntset = initIntSet()
for i in 0 .. 10:
  tIntset.incl i

const
  jsSize = len($tJs)
  tSeq = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  tString = "https://irclogs.nim-lang.org/01-06-2020.html#20:54:23"
  tObj = parseUri(tString)

#echo "benching against " & $count & " units; jsSize = " & $jsSize

bench tSeq
bench tString
bench tObj
bench tIntset
bench tJs
