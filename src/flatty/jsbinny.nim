type Buffer = string | seq[uint8]

func readUint8*(s: Buffer, i: int): uint8 {.inline.} =
  s[i].uint8

func writeUint8*(s: var Buffer, i: int, v: uint8) {.inline.} =
  s[i] = v.char

func addUint8*(s: var Buffer, v: uint8) {.inline.} =
  s.add v.char

func toUint8(v: int8): uint8 =
  var v = v.int
  if v < 0:
    v = 0xff + v + 1
  return v.uint8

func toInt8(v: uint8): int8 =
  var v = v.int
  if v > 128:
    v = v - 256
  return v.int8

func toUint16*(v: int16): uint16 =
  var v = v.int
  if v < 0:
    v = 0xffff + v + 1
  return v.uint16

func toInt16*(v: uint16): int16 =
  var v = v.int
  if v > 0x8fff:
    v = v - 0xffff - 1
  return v.int16

func readInt8*(s: Buffer, i: int): int8 {.inline.} =
  s.readUint8(i).toInt8

func writeInt8*(s: var Buffer, i: int, v: int8) {.inline.} =
  s.writeUint8(i, toUint8(v))

func addInt8*(s: var Buffer, v: int8) {.inline.} =
  s.addUint8(toUint8(v))

func readInt16*(s: Buffer, i: int): int16 {.inline.} =
  toInt16(s.readUint16(i))

func writeInt16*(s: var Buffer, i: int, v: int16) {.inline.} =
  s.writeUint16(i, toUint16(v))

func addInt16*(s: var Buffer, i: int16) {.inline.} =
  s.addUint16(toUint16(i))

func readUint16*(s: Buffer, i: int): uint16 =
  s[i+0].uint16 shl 0 +
  s[i+1].uint16 shl 8

func writeUint16*(s: var Buffer, i: int, v: uint16) =
  s[i+0] = ((v and 0x00FF) shr 0).char
  s[i+1] = ((v and 0xFF00) shr 8).char

func addUint16*(s: var Buffer, v: uint16) =
  s.add ((v and 0x00FF) shr 0).char
  s.add ((v and 0xFF00) shr 8).char

func readUint32*(s: Buffer, i: int): uint32 =
  s[i+0].uint32 shl 0 +
  s[i+1].uint32 shl 8 +
  s[i+2].uint32 shl 16 +
  s[i+3].uint32 shl 24

func writeUint32*(s: var Buffer, i: int, v: uint32) =
  s[i+0] = ((v and 0x000000FF) shr 0).char
  s[i+1] = ((v and 0x0000FF00) shr 8).char
  s[i+2] = ((v and 0x00FF0000) shr 16).char
  s[i+3] = ((v and 0xFF000000.uint32) shr 24).char

func addUint32*(s: var Buffer, v: uint32) =
  s.add ((v and 0x000000FF) shr 0).char
  s.add ((v and 0x0000FF00) shr 8).char
  s.add ((v and 0x00FF0000) shr 16).char
  s.add ((v and 0xFF000000.uint32) shr 24).char

func readInt32*(s: Buffer, i: int): int32 {.inline.} =
  cast[int32](s.readUint32(i))

func writeInt32*(s: var Buffer, i: int, v: int32) {.inline.} =
  s.writeUint32(i, cast[uint32](v))

func addInt32*(s: var Buffer, i: int32) {.inline.} =
  s.addUint32(cast[uint32](i))

func readUint64*(s: Buffer, i: int): uint64 {.inline.} =
    {.emit: """
    var uintArray = new Uint8Array(8);
    for(j = 0; j < 8; j++){
      uintArray[j] = `s`[`i` + j];
    }
    var uint64Array = new BigUint64Array(uintArray.buffer);
    return Number(uint64Array[0]);
  """.}

func writeUint64*(s: Buffer, i: int, v: uint64) {.inline.} =
    {.emit: """
    var uint64Array = new BigUint64Array(1);
    uint64Array[0] = BigInt(`v`);
    var uintArray = new Uint8Array(uint64Array.buffer);
    for(j = 0; j < 8; j++){
      `s`[`i` + j] = uintArray[j];
    }
  """.}

func addUint64*(s: var Buffer, v: uint64) {.inline.} =
  {.emit: """
    var uint64Array = new BigUint64Array(1);
    uint64Array[0] = BigInt(`v`);
    var uintArray = new Uint8Array(uint64Array.buffer);
    for(j = 0; j < 8; j++){
      `s`.push(uintArray[j]);
    }
  """.}

func readInt64*(s: Buffer, i: int): int64 {.inline.} =
    {.emit: """
    var uintArray = new Uint8Array(8);
    for(j = 0; j < 8; j++){
      uintArray[j] = `s`[`i` + j];
    }
    var uint64Array = new BigInt64Array(uintArray.buffer);
    return Number(uint64Array[0]);
  """.}

func writeInt64*(s: Buffer, i: int, v: int64) {.inline.} =
    {.emit: """
    var uint64Array = new BigInt64Array(1);
    uint64Array[0] = BigInt(`v`);
    var uintArray = new Uint8Array(uint64Array.buffer);
    for(j = 0; j < 8; j++){
      `s`[`i` + j] = uintArray[j];
    }
  """.}

func addInt64*(s: var Buffer, v: int64) {.inline.} =
  {.emit: """
    var uint64Array = new BigInt64Array(1);
    uint64Array[0] = BigInt(`v`);
    var uintArray = new Uint8Array(uint64Array.buffer);
    for(j = 0; j < 8; j++){
      `s`.push(uintArray[j]);
    }
  """.}

func readFloat32*(s: Buffer, i: int): float32 {.inline.} =
    {.emit: """
    var uintArray = new Uint8Array(4);
    for(j = 0; j < 4; j++){
      uintArray[j] = `s`[`i` + j];
    }
    var float32Array = new Float32Array(uintArray.buffer);
    return float32Array[0];
  """.}

func writeFloat32*(s: Buffer, i: int, v: float32) {.inline.} =
    {.emit: """
    var float32Array = new Float32Array(1);
    float32Array[0] = `v`;
    var uintArray = new Uint8Array(float32Array.buffer);
    for(j = 0; j < 4; j++){
      `s`[`i` + j] = uintArray[j];
    }
  """.}

func addFloat32*(s: var Buffer, v: float32) {.inline.} =
  {.emit: """
    var float32Array = new Float32Array(1);
    float32Array[0] = `v`;
    var uintArray = new Uint8Array(float32Array.buffer);
    for(j = 0; j < 4; j++){
      `s`.push(uintArray[j]);
    }
  """.}

func readFloat64*(s: Buffer, i: int): float64 {.inline.} =
    {.emit: """
    var uintArray = new Uint8Array(8);
    for(j = 0; j < 8; j++){
      uintArray[j] = `s`[`i` + j];
    }
    var float64Array = new Float64Array(uintArray.buffer);
    return float64Array[0];
  """.}

func writeFloat64*(s: Buffer, i: int, v: float64) {.inline.} =
    {.emit: """
    var float64Array = new Float64Array(1);
    float64Array[0] = `v`;
    var uintArray = new Uint8Array(float64Array.buffer);
    for(j = 0; j < 8; j++){
      `s`[`i` + j] = uintArray[j];
    }
  """.}

func addFloat64*(s: var Buffer, v: float64) {.inline.} =
  {.emit: """
    var float64Array = new Float64Array(1);
    float64Array[0] = `v`;
    var uintArray = new Uint8Array(float64Array.buffer);
    for(j = 0; j < 8; j++){
      `s`.push(uintArray[j]);
    }
  """.}

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
