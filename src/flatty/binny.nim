# Like StringStream but without the Stream and side effects.

func readUInt8*(s: string, i: int): uint8 =
  s[i].uint8

func writeUInt8*(s: var string, i: int, v: uint8) =
  s[i] = v.char

func addUInt8*(s: var string, v: uint8) =
  s.add v.char

when defined(js):
  func readUInt16*(s: string, i: int): uint16 =
    s[i+0].uint16 shl 0 +
    s[i+1].uint16 shl 8

  func writeUInt16*(s: var string, i: int, v: uint16) =
    s[i+0] = ((v and 0x00FF) shr 0).char
    s[i+1] = ((v and 0xFF00) shr 8).char

  func addUInt16*(s: var string, v: uint16) =
    s.add ((v and 0x00FF) shr 0).char
    s.add ((v and 0xFF00) shr 8).char

  func readUInt32*(s: string, i: int): uint32 =
    s[i+0].uint32 shl 0 +
    s[i+1].uint32 shl 8 +
    s[i+2].uint32 shl 16 +
    s[i+3].uint32 shl 24

  func writeUInt32*(s: var string, i: int, v: uint32) =
    s[i+0] = ((v and 0x000000FF) shr 0).char
    s[i+1] = ((v and 0x0000FF00) shr 8).char
    s[i+2] = ((v and 0x00FF0000) shr 16).char
    s[i+3] = ((v and 0xFF000000.uint32) shr 24).char

  func addUInt32*(s: var string, v: uint32) =
    s.add ((v and 0x000000FF) shr 0).char
    s.add ((v and 0x0000FF00) shr 8).char
    s.add ((v and 0x00FF0000) shr 16).char
    s.add ((v and 0xFF000000.uint32) shr 24).char

  func readUInt64*(s: string, i: int): uint64 =
    s[i+0].uint64 shl 0 +
    s[i+1].uint64 shl 8 +
    s[i+2].uint64 shl 16 +
    s[i+3].uint64 shl 24 +
    s[i+4].uint64 shl 32 +
    s[i+5].uint64 shl 40 +
    s[i+6].uint64 shl 48 +
    s[i+7].uint64 shl 56

  func writeUint64*(s: var string, i: int, v: uint64) =
    s[i+0] = ((v and (0xFF.uint64 shl 0)) shr 0).char
    s[i+1] = ((v and (0xFF.uint64 shl 8)) shr 8).char
    s[i+2] = ((v and (0xFF.uint64 shl 16)) shr 16).char
    s[i+3] = ((v and (0xFF.uint64 shl 24)) shr 24).char
    s[i+4] = ((v and (0xFF.uint64 shl 32)) shr 32).char
    s[i+5] = ((v and (0xFF.uint64 shl 40)) shr 40).char
    s[i+6] = ((v and (0xFF.uint64 shl 48)) shr 48).char
    s[i+7] = ((v and (0xFF.uint64 shl 56)) shr 56).char

  func addUint64*(s: var string, v: uint64) =
    s.add ((v and (0xFF.uint64 shl 0)) shr 0).char
    s.add ((v and (0xFF.uint64 shl 8)) shr 8).char
    s.add ((v and (0xFF.uint64 shl 16)) shr 16).char
    s.add ((v and (0xFF.uint64 shl 24)) shr 24).char
    s.add ((v and (0xFF.uint64 shl 32)) shr 32).char
    s.add ((v and (0xFF.uint64 shl 40)) shr 40).char
    s.add ((v and (0xFF.uint64 shl 48)) shr 48).char
    s.add ((v and (0xFF.uint64 shl 56)) shr 56).char
else:
  func readUInt16*(s: string, i: int): uint16 =
    copyMem(result.unsafeAddr, s[i].unsafeAddr, sizeof(result))

  func writeUInt16*(s: var string, i: int, v: uint16) =
    copyMem(s[i].addr, v.unsafeAddr, sizeof(uint64))

  func addUInt16*(s: var string, v: uint16) =
    s.setLen(s.len + sizeof(v))
    let dest = s[s.len - sizeof(v)].addr
    copyMem(dest, v.unsafeAddr, sizeof(v))

  func readUInt32*(s: string, i: int): uint32 =
    copyMem(result.unsafeAddr, s[i].unsafeAddr, sizeof(result))

  func writeUInt32*(s: var string, i: int, v: uint32) =
    copyMem(s[i].addr, v.unsafeAddr, sizeof(uint64))

  func addUInt32*(s: var string, v: uint32) =
    s.setLen(s.len + sizeof(v))
    let dest = s[s.len - sizeof(v)].addr
    copyMem(dest, v.unsafeAddr, sizeof(v))

  func readUInt64*(s: string, i: int): uint64 =
    copyMem(result.unsafeAddr, s[i].unsafeAddr, sizeof(result))

  func writeUInt64*(s: var string, i: int, v: uint64) =
    copyMem(s[i].addr, v.unsafeAddr, sizeof(uint64))

  func addUInt64*(s: var string, v: uint64) =
    s.setLen(s.len + sizeof(v))
    let dest = s[s.len - sizeof(v)].addr
    copyMem(dest, v.unsafeAddr, sizeof(v))

func readInt8*(s: string, i: int): int8 =
  cast[int8](s.readUInt8(i))

func writeInt8*(s: var string, i: int, v: int8) =
  s.writeUInt8(i, cast[uint8](v))

func addInt8*(s: var string, v: int8) =
  s.addUInt8(cast[uint8](v))

func readInt16*(s: string, i: int): int16 =
  cast[int16](s.readUInt16(i))

func writeInt16*(s: var string, i: int, v: int16) =
  s.writeUInt16(i, cast[uint16](v))

func addInt16*(s: var string, i: int16) =
  s.addUInt16(cast[uint16](i))

func readInt32*(s: string, i: int): int32 =
  cast[int32](s.readUInt32(i))

func writeInt32*(s: var string, i: int, v: int32) =
  s.writeUInt32(i, cast[uint32](v))

func addInt32*(s: var string, i: int32) =
  s.addUInt32(cast[uint32](i))

func readInt64*(s: string, i: int): int64 =
  cast[int64](s.readUInt64(i))

func writeInt64*(s: var string, i: int, v: int64) =
  s.writeUInt64(i, cast[uint64](v))

func addInt64*(s: var string, i: int64) =
  s.addUInt64(cast[uint64](i))

func readFloat32*(s: string, i: int): float32 =
  cast[float32](s.readUInt32(i))

func addFloat32*(s: var string, v: float32) =
  s.addUInt32(cast[uint32](v))

func readFloat64*(s: string, i: int): float64 =
  cast[float64](s.readUInt64(i))

func addFloat64*(s: var string, v: float64) =
  s.addUInt64(cast[uint64](v))

func addStr*(s: var string, v: string) =
  s.add(v)

func readStr*(s: string, i: int, v: int): string =
  s[i ..< min(s.len, i + v)]

func swap*(v: uint8): uint8 =
  v

func swap*(v: uint16): uint16 =
  ((v and 0x00FF) shl 8) +
  ((v and 0xFF00) shr 8)

func swap*(v: uint32): uint32 =
  ((v and (0xFF.uint32 shl 0)) shl 24) +
  ((v and (0xFF.uint32 shl 8)) shl 8) +
  ((v and (0xFF.uint32 shl 16)) shr 8) +
  ((v and (0xFF.uint32 shl 24)) shr 24)

func swap*(v: uint64): uint64 =
  ((v and (0xFF.uint64 shl 0)) shl 56) +
  ((v and (0xFF.uint64 shl 8)) shl 40) +
  ((v and (0xFF.uint64 shl 16)) shl 24) +
  ((v and (0xFF.uint64 shl 24)) shl 8) +
  ((v and (0xFF.uint64 shl 32)) shr 8) +
  ((v and (0xFF.uint64 shl 40)) shr 24) +
  ((v and (0xFF.uint64 shl 48)) shr 40) +
  ((v and (0xFF.uint64 shl 56)) shr 56)

func maybeSwap*[T](v: T, enable: bool): T =
  if enable:
    v.swap()
  else:
    v
