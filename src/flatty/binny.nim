# Like StringStream but without the Stream and side effects.

type Buffer = string | seq[uint8]

func readUint8*(s: Buffer, i: int): uint8 {.inline.} =
  s[i].uint8

func writeUint8*(s: var Buffer, i: int, v: uint8) {.inline.} =
  s[i] = v.char

func addUint8*(s: var Buffer, v: uint8) {.inline.} =
  s.add v.char

func readUint16*(s: Buffer, i: int): uint16 {.inline.} =
  result = cast[ptr uint16](s[i].unsafeAddr)[]

func writeUint16*(s: var Buffer, i: int, v: uint16) {.inline.} =
  cast[ptr uint16](s[i].addr)[] = v

func addUint16*(s: var Buffer, v: uint16) {.inline.} =
  s.setLen(s.len + sizeof(v))
  cast[ptr uint16](s[s.len - sizeof(v)].addr)[] = v

func readUint32*(s: Buffer, i: int): uint32 {.inline.} =
  result = cast[ptr uint32](s[i].unsafeAddr)[]

func writeUint32*(s: var Buffer, i: int, v: uint32) {.inline.} =
  cast[ptr uint32](s[i].addr)[] = v

func addUint32*(s: var Buffer, v: uint32) {.inline.} =
  s.setLen(s.len + sizeof(v))
  cast[ptr uint32](s[s.len - sizeof(v)].addr)[] = v

func readUint64*(s: Buffer, i: int): uint64 {.inline.} =
  result = cast[ptr uint64](s[i].unsafeAddr)[]

func writeUint64*(s: var Buffer, i: int, v: uint64) {.inline.} =
  cast[ptr uint64](s[i].addr)[] = v

func addUint64*(s: var Buffer, v: uint64) {.inline.} =
  s.setLen(s.len + sizeof(v))
  cast[ptr uint64](s[s.len - sizeof(v)].addr)[] = v

func readInt8*(s: Buffer, i: int): int8 {.inline.} =
  cast[int8](s.readUint8(i))

func writeInt8*(s: var Buffer, i: int, v: int8) {.inline.} =
  s.writeUint8(i, cast[uint8](v))

func addInt8*(s: var Buffer, v: int8) {.inline.} =
  s.addUint8(cast[uint8](v))

func readInt16*(s: Buffer, i: int): int16 {.inline.} =
  cast[int16](s.readUint16(i))

func writeInt16*(s: var Buffer, i: int, v: int16) {.inline.} =
  s.writeUint16(i, cast[uint16](v))

func addInt16*(s: var Buffer, i: int16) {.inline.} =
  s.addUint16(cast[uint16](i))

func readInt32*(s: Buffer, i: int): int32 {.inline.} =
  cast[int32](s.readUint32(i))

func writeInt32*(s: var Buffer, i: int, v: int32) {.inline.} =
  s.writeUint32(i, cast[uint32](v))

func addInt32*(s: var Buffer, i: int32) {.inline.} =
  s.addUint32(cast[uint32](i))

func readInt64*(s: Buffer, i: int): int64 {.inline.} =
  cast[int64](s.readUint64(i))

func writeInt64*(s: var Buffer, i: int, v: int64) {.inline.} =
  s.writeUint64(i, cast[uint64](v))

func addInt64*(s: var Buffer, i: int64) {.inline.} =
  s.addUint64(cast[uint64](i))

func readFloat32*(s: Buffer, i: int): float32 {.inline.} =
  cast[float32](s.readUint32(i))

func addFloat32*(s: var Buffer, v: float32) {.inline.} =
  s.addUint32(cast[uint32](v))

func writeFloat32*(s: var Buffer, i: int, v: float32) {.inline.} =
  s.writeUint32(i, cast[uint32](v))

func readFloat64*(s: Buffer, i: int): float64 {.inline.} =
  cast[float64](s.readUint64(i))

func writeFloat64*(s: var Buffer, i: int, v: float64) {.inline.} =
  s.writeUint64(i, cast[uint64](v))

func addFloat64*(s: var Buffer, v: float64) {.inline.} =
  s.addUint64(cast[uint64](v))

func addStr*(s: var string, v: string) {.inline.} =
  s.add(v)

func readStr*(s: string, i: int, v: int): string {.inline.} =
  s[i ..< min(s.len, i + v)]

func addStr*(s: var seq[uint8], v: string) {.inline.} =
  s.add(cast[seq[uint8]](v))

func readStr*(s: seq[uint8], i: int, v: int): string {.inline.} =
  cast[string](s[i ..< min(s.len, i + v)])

func swap*(v: uint8): uint8 {.inline.} =
  v

when defined(js):
  func swap*(v: uint16): uint16 =
    ((v and 0x00FF) shl 8) +
    ((v and 0xFF00) shr 8)

  func swap*(v: uint32): uint32 =
    ((v and (0xFF.uint32 shl 0)) shl 24) +
    ((v and (0xFF.uint32 shl 8)) shl 8) +
    ((v and (0xFF.uint32 shl 16)) shr 8) +
    ((v and (0xFF.uint32 shl 24)) shr 24)

  func swap*(v: int16): int16 {.inline.} =
    toInt16(toUint16(v).swap())

  func swap*(v: int32): int32 {.inline.} =
    cast[int32](cast[uint32](v).swap())

  func swap*(v: uint64): uint64 =
    ((v and (0xFF.uint64 shl 0)) shl 56) +
    ((v and (0xFF.uint64 shl 8)) shl 40) +
    ((v and (0xFF.uint64 shl 16)) shl 24) +
    ((v and (0xFF.uint64 shl 24)) shl 8) +
    ((v and (0xFF.uint64 shl 32)) shr 8) +
    ((v and (0xFF.uint64 shl 40)) shr 24) +
    ((v and (0xFF.uint64 shl 48)) shr 40) +
    ((v and (0xFF.uint64 shl 56)) shr 56)
else:
  func swap*(v: uint16): uint16 {.inline.} =
    let tmp = cast[array[2, uint8]](v)
    (tmp[0].uint16 shl 8) or tmp[1].uint16

  func swap*(v: uint32): uint32 {.inline.} =
    let tmp = cast[array[2, uint16]](v)
    (swap(tmp[0]).uint32 shl 16) or swap(tmp[1])

  func swap*(v: uint64): uint64 {.inline.} =
    let tmp = cast[array[2, uint32]](v)
    (swap(tmp[0]).uint64 shl 32) or swap(tmp[1])

  func swap*(v: int16): int16 {.inline.} =
    cast[int16](cast[uint16](v).swap())

  func swap*(v: int32): int32 {.inline.} =
    cast[int32](cast[uint32](v).swap())

  func swap*(v: int64): int64 {.inline.} =
    cast[int64](cast[uint64](v).swap())

func maybeSwap*[T](v: T, enable: bool): T =
  if enable:
    v.swap()
  else:
    v
