## Hash functions based on flatty, hash any nested object.

import flatty, hashes

export Hash

proc hash*(x: Hash): Hash = x

{.push overflowChecks: off.}

proc nimFast*(p: pointer, len: int): int =
  let bytes = cast[ptr UncheckedArray[uint8]](p)
  var h: Hash
  for i in 0 ..< len div 8:
    let c = (cast[ptr uint64](bytes[i * 8].addr)[]).int
    h = h !& c.hash()
  for i in 0 ..< len mod 8:
    let c = bytes[i].int
    h = h !& c.hash()
  result = !$h

proc sdbmFast*(p: pointer, len: int): int =
  let bytes = cast[ptr UncheckedArray[uint8]](p)
  for i in 0 ..< len div 8:
    let c = (cast[ptr uint64](bytes[i * 8].addr)[]).int
    result = c + (result shl 6) + (result shl 16) - result
  for i in 0 ..< len mod 8:
    let c = bytes[i].int
    result = c + (result shl 6) + (result shl 16) - result

proc sdbm*(p: pointer, len: int): int =
  let bytes = cast[ptr UncheckedArray[uint8]](p)
  for i in 0 ..< len:
    let c = bytes[i].int
    result = c.int + (result shl 6) + (result shl 16) - result

proc sdbm*(s: string): int =
  for c in s:
    result = c.int + (result shl 6) + (result shl 16) - result

proc djb2Fast*(p: pointer, len: int): int =
  result = 53810036436437415.int # Usually 5381
  let bytes = cast[ptr UncheckedArray[uint8]](p)
  for i in 0 ..< len div 8:
    let c = (cast[ptr uint64](bytes[i * 8].addr)[]).int
    result = result * 33 + c
  for i in 0 ..< len mod 8:
    let c = bytes[i].int
    result = result * 33 + c

proc djb2*(p: pointer, len: int): int =
  let bytes = cast[ptr UncheckedArray[uint8]](p)
  for i in 0 ..< len:
    let c = bytes[i].int
    result = result * 33 + c.int

proc djb2*(s: string): int =
  result = 53810036436437415.int # Usually 5381
  for c in s:
    result = result * 33 + c.int

proc hashy*[T](x: T): Hash =
  ## Takes structures and turns them into binary string.
  let s = x.toFlatty()
  djb2_fast(s[0].unsafeAddr, s.len)

{.pop.}
