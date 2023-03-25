## Convert any Nim objects, numbers, strings, refs to and from binary format.
when defined(js):
  import flatty/jsbinny
else:
  import flatty/binny
import flatty/objvar, tables, typetraits, sets, sequtils

type SomeTable*[K, V] = Table[K, V] | OrderedTable[K, V]
type SomeSet[A] = set[A] | HashSet[A] | OrderedSet[A]

# Forward declarations.
proc toFlatty*[T](s: var string, x: seq[T])
proc toFlatty*(s: var string, x: object)
proc toFlatty*[T: distinct](s: var string, x: T)
proc toFlatty*[K, V](s: var string, x: SomeTable[K, V])
proc toFlatty*[K](s: var string, x: CountTable[K])
proc toFlatty*[N, T](s: var string, x: array[N, T])
proc toFlatty*[T: tuple](s: var string, x: T)
proc toFlatty*[T](s: var string, x: ref T)
proc toFlatty*[T: range and float](s: var string, x: T)
proc toFlatty*[T: range and int](s: var string, x: T)

proc fromFlatty*[T](s: string, i: var int, x: var seq[T])
proc fromFlatty*(s: string, i: var int, x: var object)
proc fromFlatty*[T: distinct](s: string, i: var int, x: var T)
proc fromFlatty*[K, V](s: string, i: var int, x: var SomeTable[K, V])
proc fromFlatty*[K](s: string, i: var int, x: var CountTable[K])
proc fromFlatty*[N, T](s: string, i: var int, x: var array[N, T])
proc fromFlatty*[T: tuple](s: string, i: var int, x: var T)
proc fromFlatty*[T](s: string, x: typedesc[T]): T
proc fromFlatty*[T](s: string, i: var int, x: var ref T)

# Booleans
proc toFlatty*(s: var string, x: bool) =
  s.addUint8(x.uint8)

proc fromFlatty*(s: string, i: var int, x: var bool) =
  x = s.readUint8(i).bool
  i += 1

# Chars
proc toFlatty*(s: var string, x: char) =
  s.addUint8(x.uint8)

proc fromFlatty*(s: string, i: var int, x: var char) =
  x = s.readUint8(i).char
  i += 1

# Numbers
proc toFlatty*(s: var string, x: uint8) = s.addUint8(x)
proc toFlatty*(s: var string, x: int8) = s.addInt8(x)
proc toFlatty*(s: var string, x: uint16) = s.addUint16(x)
proc toFlatty*(s: var string, x: int16) = s.addInt16(x)
proc toFlatty*(s: var string, x: uint32) = s.addUint32(x)
proc toFlatty*(s: var string, x: int32) = s.addInt32(x)
proc toFlatty*(s: var string, x: uint64) = s.addUint64(x)
proc toFlatty*(s: var string, x: int64) = s.addInt64(x)
proc toFlatty*(s: var string, x: float32) = s.addFloat32(x)
proc toFlatty*(s: var string, x: float64) = s.addFloat64(x)

proc fromFlatty*(s: string, i: var int, x: var uint8) =
  x = s.readUint8(i)
  i += 1

proc fromFlatty*(s: string, i: var int, x: var int8) =
  x = s.readInt8(i)
  i += 1

proc fromFlatty*(s: string, i: var int, x: var uint16) =
  x = s.readUint16(i)
  i += 2

proc fromFlatty*(s: string, i: var int, x: var int16) =
  x = s.readInt16(i)
  i += 2

proc fromFlatty*(s: string, i: var int, x: var uint32) =
  x = s.readUint32(i)
  i += 4

proc fromFlatty*(s: string, i: var int, x: var int32) =
  x = s.readInt32(i)
  i += 4

proc fromFlatty*(s: string, i: var int, x: var uint64) =
  x = s.readUint64(i)
  i += 8

proc fromFlatty*(s: string, i: var int, x: var int64) =
  x = s.readInt64(i)
  i += 8

proc fromFlatty*(s: string, i: var int, x: var uint) =
  x = s.readUint64(i).uint
  i += 8

proc fromFlatty*(s: string, i: var int, x: var int) =
  x = s.readInt64(i).int
  i += 8

proc fromFlatty*(s: string, i: var int, x: var float32) =
  x = s.readFloat32(i)
  i += 4

proc fromFlatty*(s: string, i: var int, x: var float64) =
  x = s.readFloat64(i)
  i += 8

# Enums
proc toFlatty*[T: enum](s: var string, x: T) =
  s.addInt64(x.int)

proc fromFlatty*[T: enum](s: string, i: var int, x: var T) =
  x = cast[T](s.readInt64(i))
  i += 8

# Strings
proc toFlatty*(s: var string, x: string) =
  s.addInt64(x.len)
  s.add(x)

proc fromFlatty*(s: string, i: var int, x: var string) =
  let len = s.readInt64(i).int
  i += 8
  x = s[i ..< i + len]
  i += len

# Seq
proc toFlatty*[T](s: var string, x: seq[T]) =
  s.addInt64(x.len.int64)
  when not defined(js) and T.supportsCopyMem:
    if x.len == 0:
      return
    let byteLen = x.len * sizeof(T)
    s.setLen(s.len + byteLen)
    let dest = s[s.len - byteLen].addr
    copyMem(dest, x[0].unsafeAddr, byteLen)
  else:
    for e in x:
      s.toFlatty(e)

proc fromFlatty*[T](s: string, i: var int, x: var seq[T]) =
  let len = s.readInt64(i)
  i += 8
  x.setLen(len)
  when not defined(js) and T.supportsCopyMem:
    if len > 0:
      copyMem(x[0].addr, s[i].unsafeAddr, len * sizeof(T))
      i += sizeof(T) * len.int
  else:
    for j in x.mitems:
      s.fromFlatty(i, j)

# Objects
proc toFlatty*(s: var string, x: object) =
  when x.isObjectVariant:
    s.toFlatty(x.discriminatorField)
    for k, e in x.fieldPairs:
      when k != x.discriminatorFieldName:
        s.toFlatty(e)
  else:
    for e in x.fields:
      s.toFlatty(e)

proc fromFlatty*(s: string, i: var int, x: var object) =
  when x.isObjectVariant:
    var discriminator: type(x.discriminatorField)
    s.fromFlatty(i, discriminator)
    new(x, discriminator)
    for k, e in x.fieldPairs:
      when k != x.discriminatorFieldName:
        s.fromFlatty(i, e)
  else:
    for e in x.fields:
      s.fromFlatty(i, e)

# Distinct
proc toFlatty*[T: distinct](s: var string, x: T) =
  s.toFlatty(x.distinctBase)

proc fromFlatty*[T: distinct](s: string, i: var int, x: var T) =
  when defined(js):
    var z: type(x.distinctBase)
    s.fromFlatty(i, z)
    x = T(z)
  else:
    s.fromFlatty(i, x.distinctBase)

# Tables
proc toTableLike[T](s: var string, K: type, V: type, x: T) {.inline.} =
  s.addInt64(x.len.int64)
  for k, v in x:
    s.toFlatty(k)
    s.toFlatty(v)

proc fromTableLike[T](
    s: string, i: var int, K: type, V: type, x: var T
) {.inline.} =
  let len = s.readInt64(i)
  i += 8
  for _ in 0 ..< len:
    var
      k: K
      v: V
    s.fromFlatty(i, k)
    s.fromFlatty(i, v)
    x[k] = v

proc toFlatty*[K, V](s: var string, x: SomeTable[K, V]) =
  toTableLike(s, K, V, x)

proc fromFlatty*[K, V](s: string, i: var int, x: var SomeTable[K, V]) =
  fromTableLike(s, i, K, V, x)

proc toFlatty*[K](s: var string, x: CountTable[K]) =
  toTableLike(s, K, int, x)

proc fromFlatty*[K](s: string, i: var int, x: var CountTable[K]) =
  fromTableLike(s, i, K, int, x)

# Arrays
proc toFlatty*[N, T](s: var string, x: array[N, T]) =
  when not defined(js) and T.supportsCopyMem:
    if x.len == 0:
      return
    let byteLen = x.len * sizeof(T)
    s.setLen(s.len + byteLen)
    let dest = s[s.len - byteLen].addr
    copyMem(dest, x[0.N].unsafeAddr, byteLen)
  else:
    for e in x:
      s.toFlatty(e)

proc fromFlatty*[N, T](s: string, i: var int, x: var array[N, T]) =
  when not defined(js) and T.supportsCopyMem:
    if x.len > 0:
      copyMem(x[0.N].addr, s[i].unsafeAddr, sizeof(x))
      i += sizeof(x)
  else:
    for j in x.mitems:
      s.fromFlatty(i, j)

# Tuples
proc toFlatty*[T: tuple](s: var string, x: T) =
  for e in x.fields:
    s.toFlatty(e)

proc fromFlatty*[T: tuple](s: string, i: var int, x: var T) =
  for e in x.fields:
    s.fromFlatty(i, e)

# Refs
proc toFlatty*[T](s: var string, x: ref T) =
  let isNil = x == nil
  s.toFlatty(isNil)
  if not isNil:
    s.toFlatty(x[])

proc fromFlatty*[T](s: string, i: var int, x: var ref T) =
  var isNil: bool
  s.fromFlatty(i, isNil)
  if not isNil:
    new(x)
    s.fromFlatty(i, x[])

# Range
proc toFlatty*[T: range and float](s: var string, x: T) =
  s.toFlatty(x.float)

proc toFlatty*[T: range and int](s: var string, x: T) =
  s.toFlatty(x.int)

# Sets
proc toFlatty*[T](s: var string, x: SomeSet[T]) =
  s.addInt64(x.card.int64)
  for e in x:
    s.toFlatty(e)

proc fromFlatty*[T](s: string, i: var int, x: var SomeSet[T]) =
  let len = s.readInt64(i).int
  i += 8
  for j in 0 ..< len:
    var e: T
    s.fromFlatty(i, e)
    x.incl(e)

# Main entry points:
proc toFlatty*[T](x: T): string =
  ## Takes structures and turns them into binary string.
  result.toFlatty(x)

proc fromFlatty*[T](s: string, x: typedesc[T]): T =
  ## Takes binary string and turn into structures.
  var i = 0
  s.fromFlatty(i, result)
