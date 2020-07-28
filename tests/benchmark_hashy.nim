import fidget/opengl/perf, random

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
  for i in 0 ..< 1_000_000:
    let h = sdbm(short)
    assert h != 0

timeIt "short sdbm_fast":
  for i in 0 ..< 1_000_000:
    let h = sdbmFast(short[0].unsafeAddr, short.len)
    assert h != 0

timeIt "short djb2":
  for i in 0 ..< 1_000_000:
    let h = djb2(short)
    assert h != 0

timeIt "short djb2_fast":
  for i in 0 ..< 1_000_000:
    let h = djb2Fast(short[0].unsafeAddr, short.len)
    assert h != 0

timeIt "short string":
  for i in 0 ..< 1_000_000:
    let h = hash(short)
    assert h != 0

timeIt "short nim byte hash":
  for i in 0 ..< 1_000_000:
    var h: Hash
    for c in short:
      h = h !& hash(c)
    assert h != 0

timeIt "short nim fast hash":
  for i in 0 ..< 1_000_000:
    var h = nimFast(short[0].unsafeAddr, short.len)
    assert h != 0

timeIt "long sdbm":
  for i in 0 ..< 100:
    let h = sdbm(long)
    assert h != 0

timeIt "long sdbm_fast":
  for i in 0 ..< 100:
    let h = sdbmFast(long[0].unsafeAddr, long.len)
    assert h != 0

timeIt "long djb2":
  for i in 0 ..< 100:
    let h = djb2(long)
    assert h != 0

timeIt "long djb2_fast":
  for i in 0 ..< 100:
    let h = djb2Fast(long[0].unsafeAddr, long.len)
    assert h != 0

timeIt "long string":
  for i in 0 ..< 100:
    let h = hash(long)
    assert h != 0

timeIt "long nim byte hash":
  for i in 0 ..< 100:
    var h: Hash
    for c in long:
      h = h !& hash(c)
    assert h != 0

timeIt "long nim fast hash":
  for i in 0 ..< 100:
    var h = nimFast(long[0].unsafeAddr, long.len)
    assert h != 0
