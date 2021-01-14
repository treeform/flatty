import benchy, streams, flatty/binny

block:
  var s = newStringStream()
  for i in 0 .. 100000:
    s.write(i.uint32)
  var s2 = ""
  for i in 0 .. 100000:
    s2.addUInt32(i.uint32)
  doAssert s.data == s2

timeIt "streams", 100:
  var s = newStringStream()
  for i in 0 .. 100000:
    s.write(i.uint32)
  keep s.data

timeIt "binny", 100:
  var s = ""
  for i in 0 .. 100000:
    s.addUInt32(i.uint32)
  keep s
