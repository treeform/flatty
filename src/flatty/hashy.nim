## Hash functions based on flatty, hash any nested object.

import
  std/hashes,
  flatty

export Hash

proc hash*(x: Hash): Hash = x

when defined(js):
  const Djb2Seed = 5381
else:
  const Djb2Seed = 53810036436437415.int

{.push overflowChecks: off.}

when defined(release):
  {.push checks: off.}

proc ryan64nim*(s: string): int =
  var h: Hash
  for c in s:
    let c = c.int
    h = h !& c.hash()
  result = !$h

proc ryan64sdbm*(s: string): int =
  for c in s:
    let c = c.int
    result = c + (result shl 6) + (result shl 16) - result

proc sdbm*(s: string): int =
  for c in s:
    result = c.int + (result shl 6) + (result shl 16) - result

proc ryan64djb2*(s: string): int =
  when defined(js):
    var h = Djb2Seed.uint32
    for c in s:
      h = h * 33'u32 + ord(c).uint32
    result = cast[int32](h).int
  else:
    result = Djb2Seed
    for c in s:
      let c = c.int
      result = result * 33 + c

proc djb2*(s: string): int =
  when defined(js):
    var h = Djb2Seed.uint32
    for c in s:
      h = h * 33'u32 + ord(c).uint32
    result = cast[int32](h).int
  else:
    result = Djb2Seed
    for c in s:
      result = result * 33 + c.int

when not defined(js):
  proc ryan64nim*(p: pointer, len: int): int =
    let
      bytes = cast[ptr UncheckedArray[uint8]](p)
      ints = cast[ptr UncheckedArray[int]](p)
      intSize = sizeof(int)
    var
      h: Hash
      start = 0
      stop = len div intSize
    for i in start ..< stop:
      var c: int
      copyMem(c.addr, ints[i].addr, intSize)
      h = h !& c.hash()
    start = stop * 8
    for i in start ..< len:
      let c = bytes[i].int
      h = h !& c.hash()
    result = !$h

  proc ryan64sdbm*(p: pointer, len: int): int =
    let
      bytes = cast[ptr UncheckedArray[uint8]](p)
      ints = cast[ptr UncheckedArray[int]](p)
      intSize = sizeof(int)
    var
      start = 0
      stop = len div intSize
    for i in start ..< stop:
      var c: int
      copyMem(c.addr, ints[i].addr, intSize)
      result = c + (result shl 6) + (result shl 16) - result
    start = stop * 8
    for i in start ..< len:
      let c = bytes[i].int
      result = c + (result shl 6) + (result shl 16) - result

  proc sdbm*(p: pointer, len: int): int =
    let bytes = cast[ptr UncheckedArray[uint8]](p)
    for i in 0 ..< len:
      let c = bytes[i].int
      result = c.int + (result shl 6) + (result shl 16) - result

  proc ryan64djb2*(p: pointer, len: int): int =
    result = Djb2Seed
    let
      bytes = cast[ptr UncheckedArray[uint8]](p)
      ints = cast[ptr UncheckedArray[int]](p)
      intSize = sizeof(int)
    var
      start = 0
      stop = len div intSize
    for i in start ..< stop:
      var c: int
      copyMem(c.addr, ints[i].addr, intSize)
      result = result * 33 + c
    start = stop * 8
    for i in start ..< len:
      let c = bytes[i].int
      result = result * 33 + c

  proc djb2*(p: pointer, len: int): int =
    result = Djb2Seed
    let bytes = cast[ptr UncheckedArray[uint8]](p)
    for i in 0 ..< len:
      let c = bytes[i].int
      result = result * 33 + c.int

  proc hashy*(p: pointer, len: int): Hash =
    ryan64djb2(p, len)

proc hashy*[T](x: T): Hash =
  ## Takes structures and turns them into binary string.
  let s = x.toFlatty()
  when defined(js):
    ryan64djb2(s)
  else:
    hashy(s[0].unsafeAddr, s.len)

when defined(release):
  {.pop.}

{.pop.}
