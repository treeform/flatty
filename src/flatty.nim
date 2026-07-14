## Convert any Nim objects, numbers, strings, refs to and from binary format.
import
  std/[importutils, macros, tables, typetraits, sets],
  flatty/objvar

when defined(js):
  import flatty/jsbinny
else:
  import flatty/binny
  import std/[asyncdispatch, nativesockets]

type SomeTable*[K, V] = Table[K, V] | OrderedTable[K, V]
type SomeSet[A] = set[A] | HashSet[A] | OrderedSet[A]

type FlattyError* = object of CatchableError
  ## Raised when decoding malformed input: a negative or oversized length /
  ## element count, or an undefined enum discriminator (out of range or a
  ## hole in a discontinuous enum). Truncated reads raise IndexDefect from
  ## the binny layer; catch both to fully contain a hostile payload.

const flattyPreallocCap = 4096
  ## Upper bound on how many slots a Table/Set decode will preallocate from an
  ## untrusted element count. This makes the preallocation a bounded constant
  ## (~a few hundred KB, freed on error) regardless of the claimed count, so a
  ## small payload can't force a huge hash-table allocation, while still
  ## preallocating exactly for the common case of tables up to this size.
  ## Larger containers grow organically as their real entries decode.

template checkCount(s: string, i, count, elemSize: int) =
  ## Reject a length/count prefix that cannot possibly be backed by the
  ## bytes remaining in the buffer. Every value flatty encodes occupies at
  ## least one byte, so a container can never hold more elements than there
  ## are bytes left. Phrased to avoid overflow on a hostile `count`.
  ##
  ## NOTE: types that serialize to zero bytes (e.g. an empty object with no
  ## fields) violate the >=1-byte assumption; a very large seq of those will
  ## be rejected. That is a deliberate trade for a bound that needs no
  ## configuration.
  if count < 0 or (elemSize > 0 and count > (s.len - i) div elemSize):
    raise newException(
      FlattyError,
      "flatty: element count " & $count & " exceeds " & $(s.len - i) &
        " bytes remaining"
    )

# Deeply nested input (a long ref/seq chain) would otherwise recurse until the
# thread stack overflows -- an uncatchable crash that no length check stops.
# Rather than thread a depth counter through every call (and unwind it on the
# way back up), we watch the actual stack pointer: the hardware stack already
# counts depth for us, returns need no bookkeeping, and sibling recursion
# self-corrects. We bail a fixed margin before the thread's real stack end,
# queried once from the OS so the guard adapts to frame size, build mode, and
# per-thread stack size.
when not defined(js):
  const flattyStackMargin = 128 * 1024
    ## Stop recursing this many bytes before the true end of the stack, so the
    ## unwinding `raise` itself has room to run.

  var flattyStackLimit {.threadvar.}: uint
    ## Lowest safe stack address for this thread; recursion bails once the
    ## stack pointer drops below it. 0 means "not yet computed" -> guard off.

  proc flattyComputeStackLimit(): uint =
    ## Lowest safe address = (far end of this thread's stack) + margin.
    when defined(windows):
      proc getCurrentThreadStackLimits(lowLimit, highLimit: ptr uint) {.
        importc: "GetCurrentThreadStackLimits", stdcall, dynlib: "kernel32".}
      var lo, hi: uint
      getCurrentThreadStackLimits(addr lo, addr hi)
      lo + flattyStackMargin
    elif defined(macosx):
      proc pthread_self(): pointer {.importc, header: "<pthread.h>".}
      proc pthread_get_stackaddr_np(t: pointer): pointer {.
        importc, header: "<pthread.h>".}
      proc pthread_get_stacksize_np(t: pointer): culong {.
        importc, header: "<pthread.h>".}
      let t = pthread_self()
      # stackaddr_np is the base (highest address); the stack grows down.
      let base = cast[uint](pthread_get_stackaddr_np(t))
      let size = pthread_get_stacksize_np(t).uint
      base - size + flattyStackMargin
    elif defined(posix):
      type PthreadAttr {.importc: "pthread_attr_t", header: "<pthread.h>",
        bycopy.} = object
        abi: array[64, uint8]  # opaque; sized generously
      proc pthread_self(): culong {.importc, header: "<pthread.h>".}
      proc pthread_getattr_np(t: culong, a: ptr PthreadAttr): cint {.
        importc, header: "<pthread.h>".}
      proc pthread_attr_getstack(a: ptr PthreadAttr, stackaddr: ptr pointer,
        stacksize: ptr culong): cint {.importc, header: "<pthread.h>".}
      proc pthread_attr_destroy(a: ptr PthreadAttr): cint {.
        importc, header: "<pthread.h>".}
      var a: PthreadAttr
      if pthread_getattr_np(pthread_self(), addr a) != 0:
        return 0  # can't tell; leave the guard off rather than false-trip
      var lo: pointer
      var size: culong
      discard pthread_attr_getstack(addr a, addr lo, addr size)
      discard pthread_attr_destroy(addr a)
      # getstack returns the lowest address directly.
      cast[uint](lo) + flattyStackMargin
    else:
      0  # unknown platform: guard disabled

  template flattyInitStackGuard() =
    flattyStackLimit = flattyComputeStackLimit()

  template flattyStackGuard() =
    ## One-line guard at each recursive descent. A cycle in a Nim type must
    ## pass through a heap indirection (ref/seq/Table/HashSet) every loop, so
    ## guarding only those procs catches all unbounded recursion while leaving
    ## the common object/tuple/array paths untouched.
    var probe {.volatile.}: int
    if flattyStackLimit != 0'u and cast[uint](addr probe) < flattyStackLimit:
      raise newException(FlattyError, "flatty: input nesting too deep")
else:
  template flattyInitStackGuard() = discard
  template flattyStackGuard() = discard

when defined(flatty32) and defined(flatty64):
  {.error: "flatty32 and flatty64 cannot both be defined".}

const FlattyIntSize =
  when defined(flatty32):
    4
  elif defined(flatty64):
    8
  else:
    sizeof(int)

when not defined(js):
  type UnsupportedHandle = AsyncFD | SocketHandle

const unsupportedTypeMsg =
  "flatty can only serialize Nim-owned values; raw pointers, cstrings, procs, " &
  "and distinct OS handles cannot be flattened"

func skipsFlattyCopyMem[T](_: typedesc[T]): bool =
  when defined(js):
    false
  else:
    T is UnsupportedHandle

func hasModeInt[T](_: typedesc[T]): bool =
  when (T is int) or (T is uint):
    true
  elif T is distinct:
    typeof(default(T).distinctBase).hasModeInt
  elif T is object:
    when default(T).isObjectVariant:
      true
    else:
      block:
        var found {.compileTime.} = false
        for field in default(T).fields:
          found = found or typeof(field).hasModeInt
        found
  elif T is tuple:
    block:
      var found {.compileTime.} = false
      for field in default(T).fields:
        found = found or typeof(field).hasModeInt
      found
  elif T is array:
    typeof(default(T)[low(T)]).hasModeInt
  else:
    false

func copyable[T](_: typedesc[T]): bool =
  when not T.supportsCopyMem:
    false
  elif FlattyIntSize != sizeof(int) and T.hasModeInt:
    false
  elif skipsFlattyCopyMem(T):
    false
  elif T is range:
    false
  elif (T is pointer) or (T is ptr) or (T is cstring) or (T is proc):
    false
  elif T is distinct:
    typeof(default(T).distinctBase).copyable
  elif T is object:
    when default(T).isObjectVariant:
      false
    else:
      block:
        var ok {.compileTime.} = true
        for field in default(T).fields:
          ok = ok and typeof(field).copyable
        ok
  elif T is tuple:
    block:
      var ok {.compileTime.} = true
      for field in default(T).fields:
        ok = ok and typeof(field).copyable
      ok
  elif T is array:
    typeof(default(T)[low(T)]).copyable
  else:
    true

template writeFlattyInt(s: var string, i: int, x: int) =
  when FlattyIntSize == 4:
    s.writeInt32(i, x.int32)
  else:
    s.writeInt64(i, x.int64)

template addFlattyInt(s: var string, x: int) =
  when FlattyIntSize == 4:
    s.addInt32(x.int32)
  else:
    s.addInt64(x.int64)

template addFlattyUInt(s: var string, x: uint) =
  when FlattyIntSize == 4:
    s.addUint32(x.uint32)
  else:
    s.addUint64(x.uint64)

template readFlattyInt(s: string, i: var int): untyped =
  block:
    when FlattyIntSize == 4:
      let value = s.readInt32(i).int
      i += 4
      value
    else:
      let value = s.readInt64(i).int
      i += 8
      value

template readFlattyUInt(s: string, i: var int): untyped =
  block:
    when FlattyIntSize == 4:
      let value = s.readUint32(i).uint
      i += 4
      value
    else:
      let value = s.readUint64(i).uint
      i += 8
      value

# Forward declarations.
proc toFlatty*[T](s: var string, x: seq[T])
proc toFlatty*[T: object](s: var string, x: T)
proc toFlatty*[T: distinct](s: var string, x: T)
proc toFlatty*[K, V](s: var string, x: SomeTable[K, V])
proc toFlatty*[K](s: var string, x: CountTable[K])
proc toFlatty*[N, T](s: var string, x: array[N, T])
proc toFlatty*[T: tuple](s: var string, x: T)
proc toFlatty*[T](s: var string, x: ref T)
proc toFlatty*[T](s: var string, x: SomeSet[T])
proc toFlatty*(s: var string, x: bool)
proc toFlatty*(s: var string, x: char)
proc toFlatty*(s: var string, x: uint8)
proc toFlatty*(s: var string, x: int8)
proc toFlatty*(s: var string, x: uint16)
proc toFlatty*(s: var string, x: int16)
proc toFlatty*(s: var string, x: uint32)
proc toFlatty*(s: var string, x: int32)
proc toFlatty*(s: var string, x: uint64)
proc toFlatty*(s: var string, x: int64)
proc toFlatty*(s: var string, x: float32)
proc toFlatty*(s: var string, x: float64)
proc toFlatty*(s: var string, x: int)
proc toFlatty*(s: var string, x: uint)
proc toFlatty*[T: range](s: var string, x: T)
proc toFlatty*[T: enum and not range](s: var string, x: T)
proc toFlatty*(s: var string, x: string)

proc fromFlatty*[T](s: string, i: var int, x: var seq[T])
proc fromFlatty*[T: object](s: string, i: var int, x: var T)
proc fromFlatty*[T: distinct](s: string, i: var int, x: var T)
proc fromFlatty*[K, V](s: string, i: var int, x: var SomeTable[K, V])
proc fromFlatty*[K](s: string, i: var int, x: var CountTable[K])
proc fromFlatty*[N, T](s: string, i: var int, x: var array[N, T])
proc fromFlatty*[T: tuple](s: string, i: var int, x: var T)
proc fromFlatty*[T](s: string, i: var int, x: var ref T)
proc fromFlatty*[T](s: string, i: var int, x: var SomeSet[T])
proc fromFlatty*(s: string, i: var int, x: var bool)
proc fromFlatty*(s: string, i: var int, x: var char)
proc fromFlatty*(s: string, i: var int, x: var uint8)
proc fromFlatty*(s: string, i: var int, x: var int8)
proc fromFlatty*(s: string, i: var int, x: var uint16)
proc fromFlatty*(s: string, i: var int, x: var int16)
proc fromFlatty*(s: string, i: var int, x: var uint32)
proc fromFlatty*(s: string, i: var int, x: var int32)
proc fromFlatty*(s: string, i: var int, x: var uint64)
proc fromFlatty*(s: string, i: var int, x: var int64)
proc fromFlatty*(s: string, i: var int, x: var int)
proc fromFlatty*(s: string, i: var int, x: var uint)
proc fromFlatty*(s: string, i: var int, x: var float32)
proc fromFlatty*(s: string, i: var int, x: var float64)
proc fromFlatty*[T: range](s: string, i: var int, x: var T)
proc fromFlatty*[T: enum and not range](s: string, i: var int, x: var T)
proc fromFlatty*(s: string, i: var int, x: var string)

# Unsupported runtime resources.
proc toFlatty*(s: var string, x: pointer) {.error: unsupportedTypeMsg.}
proc fromFlatty*(s: string, i: var int, x: var pointer) {.error: unsupportedTypeMsg.}
proc toFlatty*[T](s: var string, x: ptr T) {.error: unsupportedTypeMsg.}
proc fromFlatty*[T](s: string, i: var int, x: var ptr T) {.error: unsupportedTypeMsg.}
proc toFlatty*(s: var string, x: cstring) {.error: unsupportedTypeMsg.}
proc fromFlatty*(s: string, i: var int, x: var cstring) {.error: unsupportedTypeMsg.}
proc toFlatty*(s: var string, x: proc) {.error: unsupportedTypeMsg.}
proc fromFlatty*(s: string, i: var int, x: var proc) {.error: unsupportedTypeMsg.}

when not defined(js):
  proc toFlatty*[T: UnsupportedHandle](s: var string, x: T) {.error: unsupportedTypeMsg.}
  proc fromFlatty*[T: UnsupportedHandle](s: string, i: var int, x: var T) {.error: unsupportedTypeMsg.}

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

proc toFlatty*(s: var string, x: int) =
  s.addFlattyInt(x)

proc toFlatty*(s: var string, x: uint) =
  s.addFlattyUInt(x)

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

proc fromFlatty*(s: string, i: var int, x: var int) =
  x = s.readFlattyInt(i)

proc fromFlatty*(s: string, i: var int, x: var uint) =
  x = s.readFlattyUInt(i)

proc fromFlatty*(s: string, i: var int, x: var float32) =
  x = s.readFloat32(i)
  i += 4

proc fromFlatty*(s: string, i: var int, x: var float64) =
  x = s.readFloat64(i)
  i += 8

# Ranges
proc toFlatty*[T: range](s: var string, x: T) =
  s.toFlatty(x.rangeBase)

proc fromFlatty*[T: range](s: string, i: var int, x: var T) =
  var value: rangeBase(T)
  s.fromFlatty(i, value)
  if value < low(T).rangeBase or value > high(T).rangeBase:
    raise newException(RangeDefect, "value out of range")
  x = T(value)

# Enums
proc toFlatty*[T: enum and not range](s: var string, x: T) =
  s.addInt64(x.int)

macro flattyEnumOrds(T: typedesc[enum]): untyped =
  ## Defined ordinals of `T` as a compile-time `array` of `int64`.
  ## Only needed for holey enums, where `low..high` is not a valid
  ## membership test (and `items` / `succ` are unavailable).
  result = nnkBracket.newTree()
  let impl = getTypeImpl(T.getType[1])
  for c in impl:
    if c.kind == nnkSym:
      result.add newCall(bindSym"int64", newCall(bindSym"ord", c))

proc fromFlatty*[T: enum and not range](s: string, i: var int, x: var T) =
  let value = s.readInt64(i)
  i += 8
  # An undefined discriminator is the dangerous case: for an object variant
  # it reaches `new(x, discriminator)` with a bad ordinal and can segfault
  # or silently take the wrong branch under -d:danger.
  when T is Ordinal:
    # Contiguous enum: every value in low..high is defined, so a range
    # check is exact and cheaper than scanning the ordinal list.
    if value < low(T).int64 or value > high(T).int64:
      raise newException(
        FlattyError,
        "flatty: enum value " & $value & " out of range for " & $T
      )
  else:
    # Holey enum: low..high includes gaps; require a defined ordinal.
    const ords = flattyEnumOrds(T)
    var ok = false
    for o in ords:
      if o == value:
        ok = true
        break
    if not ok:
      raise newException(
        FlattyError,
        "flatty: enum value " & $value & " out of range for " & $T
      )
  x = cast[T](value)

# Strings
proc toFlatty*(s: var string, x: string) =
  s.addFlattyInt(x.len)
  s.add(x)

proc fromFlatty*(s: string, i: var int, x: var string) =
  let len = s.readFlattyInt(i)
  s.checkCount(i, len, 1)
  when defined(js):
    x = s[i ..< i + len]
  else:
    x = newStringUninit(len)
    if len > 0:
      copyMem(x[0].addr, s[i].unsafeAddr, len)
  i += len

# Seq
proc toFlatty*[T](s: var string, x: seq[T]) =
  when not defined(js) and T.copyable:
    let
      oldLen = s.len
      byteLen = x.len * sizeof(T)
    s.setLen(oldLen + FlattyIntSize + byteLen)
    s.writeFlattyInt(oldLen, x.len)
    if byteLen > 0:
      copyMem(s[oldLen + FlattyIntSize].addr, x[0].unsafeAddr, byteLen)
  else:
    s.addFlattyInt(x.len)
    for e in x:
      s.toFlatty(e)

proc fromFlatty*[T](s: string, i: var int, x: var seq[T]) =
  let len = s.readFlattyInt(i)
  when not defined(js) and T.copyable:
    s.checkCount(i, len, sizeof(T))
    when declared(setLenUninit):
      x.setLenUninit(len)
    else:
      x.setLen(len)
    if len > 0:
      copyMem(x[0].addr, s[i].unsafeAddr, len * sizeof(T))
      i += sizeof(T) * len
  else:
    # Element-wise types occupy at least one byte each; bound the count by
    # the bytes remaining so a bogus length can't drive a huge setLen.
    flattyStackGuard()
    s.checkCount(i, len, 1)
    x.setLen(len)
    for j in x.mitems:
      s.fromFlatty(i, j)

# Objects
proc toFlatty*[T: object](s: var string, x: T) =
  privateAccess(T)
  when x.isObjectVariant:
    s.toFlatty(x.discriminatorField)
    for k, e in x.fieldPairs:
      when k != x.discriminatorFieldName:
        s.toFlatty(e)
  else:
    for e in x.fields:
      s.toFlatty(e)

proc fromFlatty*[T: object](s: string, i: var int, x: var T) =
  privateAccess(T)
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
  s.addFlattyInt(x.len)
  for k, v in x:
    s.toFlatty(k)
    s.toFlatty(v)

proc fromTableLike[T](
    s: string, i: var int, K: type, V: type, x: var T
) {.inline.} =
  flattyStackGuard()
  let len = s.readFlattyInt(i)
  # `len` is bounded by the bytes remaining, but a hash slot is far larger
  # than one byte, so preallocating `len` slots from an untrusted count is a
  # memory-amplification DoS (a ~0.5MB payload can force tens of MB). Clamp
  # the preallocation hint; a genuinely large table just grows as its real,
  # byte-backed entries are decoded below.
  s.checkCount(i, len, 1)
  let prealloc = min(len, flattyPreallocCap)
  when T is Table[K, V]:
    x = initTable[K, V](prealloc)
  elif T is OrderedTable[K, V]:
    x = initOrderedTable[K, V](prealloc)
  elif T is CountTable[K]:
    x = initCountTable[K](prealloc)
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
  when not defined(js) and T.copyable:
    if x.len == 0:
      return
    let byteLen = x.len * sizeof(T)
    let oldLen = s.len
    s.setLen(oldLen + byteLen)
    copyMem(s[oldLen].addr, x[low(x)].unsafeAddr, byteLen)
  else:
    for e in x:
      s.toFlatty(e)

proc fromFlatty*[N, T](s: string, i: var int, x: var array[N, T]) =
  when not defined(js) and T.copyable:
    if x.len > 0:
      # Array length is fixed, but the buffer may be short of sizeof(x).
      if i < 0 or sizeof(x) > s.len - i:
        raise newException(
          FlattyError,
          "flatty: array needs " & $sizeof(x) & " bytes, " &
            $(s.len - i) & " remaining"
        )
      copyMem(x[low(x)].addr, s[i].unsafeAddr, sizeof(x))
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
  s.addUint8(isNil.uint8)
  if not isNil:
    s.toFlatty(x[])

proc fromFlatty*[T](s: string, i: var int, x: var ref T) =
  flattyStackGuard()
  let isNil = s.readUint8(i).bool
  i += 1
  if not isNil:
    new(x)
    s.fromFlatty(i, x[])

# Sets
proc toFlatty*[T](s: var string, x: SomeSet[T]) =
  s.addFlattyInt(x.card)
  for e in x:
    s.toFlatty(e)

proc fromFlatty*[T](s: string, i: var int, x: var SomeSet[T]) =
  flattyStackGuard()
  let len = s.readFlattyInt(i)
  # Clamp the preallocation hint; see fromTableLike for the amplification.
  s.checkCount(i, len, 1)
  let prealloc = min(len, flattyPreallocCap)
  when x is HashSet[T]:
    x = initHashSet[T](prealloc)
  elif x is OrderedSet[T]:
    x = initOrderedSet[T](prealloc)
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
  flattyInitStackGuard()
  var i = 0
  s.fromFlatty(i, result)
