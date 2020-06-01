## Hash functions based on flatty, hash any nested object.

import flatty, hashes

export Hash

proc hash*(x: Hash): Hash = x

{.push overflowChecks: off.}
proc sdbm(s: string): int =
  for c in s:
    result = c.int + (result shl 6) + (result shl 16) - result

proc djb2(s: string): int =
  result = 53810036436437415.int # Usually 5381
  for c in s:
    result = result * 33 + c.int

proc hashy*[T](x: T): Hash =
  ## Takes structures and turns them into binary string.
  let s = x.toFlatty()
  djb2(s)
{.pop.}
