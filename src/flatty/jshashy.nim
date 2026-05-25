## JavaScript hash functions based on flatty, hash any nested object.

import
  std/hashes,
  flatty

export Hash

proc hash*(x: Hash): Hash = x

{.push overflowChecks: off.}

when defined(release):
  {.push checks: off.}

proc ryan64nim*(s: string): int =
  var h: Hash
  for c in s:
    h = h !& ord(c).hash()
  result = !$h

proc ryan64sdbm*(s: string): int =
  for c in s:
    let c = ord(c)
    result = c + (result shl 6) + (result shl 16) - result

proc sdbm*(s: string): int =
  for c in s:
    let c = ord(c)
    result = c + (result shl 6) + (result shl 16) - result

proc djb2Hash(s: string): int =
  var h = 5381'u32
  for c in s:
    h = h * 33'u32 + ord(c).uint32
  result = cast[int32](h).int

proc ryan64djb2*(s: string): int =
  djb2Hash(s)

proc djb2*(s: string): int =
  djb2Hash(s)

proc hashy*[T](x: T): Hash =
  ## Takes structures and turns them into binary string.
  ryan64djb2(x.toFlatty())

when defined(release):
  {.pop.}

{.pop.}
