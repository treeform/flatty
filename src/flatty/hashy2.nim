## Hash functions based on flatty, hash any nested object.

import flatty/objvar, typetraits

{.push overflowChecks: off.}

when defined(release):
  {.push checks: off.}

proc addHashy*[T](h: var uint32, x: seq[T])
proc addHashy*(h: var uint32, x: SomeNumber|bool|enum)
proc addHashy*(h: var uint32, x: string)
proc addHashy*(h: var uint32, x: object)
proc addHashy*[T: distinct](h: var uint32, x: T)
proc addHashy*[N, T](h: var uint32, x: array[N, T])
proc addHashy*[T: tuple](h: var uint32, x: T)
proc addHashy*[T](h: var uint32, x: ref T)

proc hashMem*(p: pointer, len: int): uint32 =
  ## Ryan's 64bit dbj2 variant.
  let
    bytes = cast[ptr UncheckedArray[uint8]](p)
    ints = cast[ptr UncheckedArray[uint64]](p)
    intSize = sizeof(int)
  var
    start = 0
    stop = len div intSize
  for i in start ..< stop:
    let c = ints[i]
    result = result * 33 + c.uint32
  start = stop * 8
  for i in start ..< len:
    let c = bytes[i].int
    result = result * 33 + c.uint32 + (c.shr(32)).uint32

proc addHashy*(h: var uint32, x: SomeNumber|bool|enum) =
  h = h * 33 + cast[uint32](x)

proc addHashy*(h: var uint32, x: string) =
  h.addHashy(x.len)
  if x.len > 0:
    h = h * 33 + hashMem(x[0].unsafeAddr, x.len)

proc addHashy*[T](h: var uint32, x: seq[T]) =
  h.addHashy(x.len)
  if x.len > 0:
    when T.supportsCopyMem:
      h = h * 33 + hashMem(x[0].unsafeAddr, x.len * sizeof(T))
    else:
      for e in x:
        h.addHashy(e)

proc addHashy*[N, T](h: var uint32, x: array[N, T]) =
  h.addHashy(x.len)
  if x.len > 0:
    when T.supportsCopyMem:
      h = h * 33 + hashMem(x[0].unsafeAddr, x.len * sizeof(T))
    else:
      for e in x:
        h.addHashy(e)

proc addHashy*(h: var uint32, x: object) =
  when type(x).supportsCopyMem:
    h = h * 33 + hashMem(x.unsafeAddr, sizeof(x))
  elif x.isObjectVariant:
    h.addHashy(x.discriminatorField)
    for k, e in x.fieldPairs:
      when k != x.discriminatorFieldName:
        h.addHashy(e)
  else:
    for e in x.fields:
      h.addHashy(e)

proc addHashy*[T: tuple](h: var uint32, x: T) =
  for e in x.fields:
    h.addHashy(e)

proc addHashy*[T: distinct](h: var uint32, x: T) =
  h.addHashy(x.distinctBase)

proc addHashy*[T](h: var uint32, x: ref T) =
  let isNil = x == nil
  h.addHashy(isNil)
  if not isNil:
    h.addHashy(x[])

proc hashy*[T](x: T): uint32 =
  ## Takes structures and hashes them.
  result = 538100364
  result.addHashy(x)

when defined(release):
  {.pop.}

{.pop.}
