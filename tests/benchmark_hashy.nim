import benchy, random

include flatty/hashy

var
  r = initRand(1988)
  short = newString(512)
  long = newString(32 * 1024 * 1024)

for i in 0 ..< short.len:
  short[i] = r.rand(255).char

for i in 0 ..< long.len:
  long[i] = r.rand(255).char

timeIt "short sdbm":
  for i in 0 ..< 1_000:
    let h = sdbm(short)
    assert h != 0
    keep(h)

timeIt "short ryan64sdbm":
  for i in 0 ..< 1_000:
    let h = ryan64sdbm(short[0].unsafeAddr, short.len)
    assert h != 0
    keep(h)

timeIt "short djb2":
  for i in 0 ..< 1_000:
    let h = djb2(short)
    assert h != 0
    keep(h)

timeIt "short ryan64djb2":
  for i in 0 ..< 1_000:
    let h = ryan64djb2(short[0].unsafeAddr, short.len)
    assert h != 0
    keep(h)

timeIt "short string":
  for i in 0 ..< 1_000:
    let h = hash(short)
    assert h != 0
    keep(h)

timeIt "short nim byte hash":
  for i in 0 ..< 1_000:
    var h: Hash
    for c in short:
      h = h !& hash(c)
    assert h != 0
    keep(h)

timeIt "short nim fast hash":
  for i in 0 ..< 1_000:
    var h = ryan64nim(short[0].unsafeAddr, short.len)
    assert h != 0
    keep(h)

timeIt "long sdbm":
  let h = sdbm(long)
  assert h != 0
  keep(h)

timeIt "long ryan64sdbm":
  let h = ryan64sdbm(long[0].unsafeAddr, long.len)
  assert h != 0
  keep(h)

timeIt "long djb2":
  let h = djb2(long)
  assert h != 0
  keep(h)

timeIt "long ryan64djb2":
  let h = ryan64djb2(long[0].unsafeAddr, long.len)
  assert h != 0
  keep(h)

timeIt "long string":
  let h = hash(long)
  assert h != 0
  keep(h)

timeIt "long nim byte hash":
  var h: Hash
  for c in long:
    h = h !& hash(c)
  assert h != 0
  keep(h)

timeIt "long nim fast hash":
  var h = ryan64nim(long[0].unsafeAddr, long.len)
  assert h != 0
  keep(h)
