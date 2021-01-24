import flatty/binny, flatty/hexPrint

block:
  var s = ""
  s.addUint8(0x12.uint8)
  doAssert cast[seq[uint8]](s) == @[18.uint8]
  s = newString(1)
  s.writeUint8(0, 0x12.uint8)
  doAssert cast[seq[uint8]](s) == @[18.uint8]
  doAssert s.readUint8(0) == 0x12.uint8
  echo hexPrint(s)

block:
  var s = ""
  s.addUint16(0x1234.uint16)
  doAssert cast[seq[uint8]](s) == @[52.uint8, 18]
  s = newString(2)
  s.writeUint16(0, 0x1234.uint16)
  doAssert cast[seq[uint8]](s) == @[52.uint8, 18]
  doAssert s.readUint16(0) == 0x1234.uint16
  echo hexPrint(s)

block:
  var s = ""
  s.addUint32(0x12345678.uint32)
  doAssert cast[seq[uint8]](s) == @[120.uint8, 86, 52, 18]
  s = newString(4)
  s.writeUint32(0, 0x12345678.uint32)
  doAssert cast[seq[uint8]](s) == @[120.uint8, 86, 52, 18]
  doAssert s.readUint32(0) == 0x12345678.uint32
  echo hexPrint(s)

block:
  var s = ""
  s.addUint64(0x12345678AABBCC.uint64)
  doAssert cast[seq[uint8]](s) == @[204.uint8, 187, 170, 120, 86, 52, 18, 0]
  s = newString(8)
  s.writeUint64(0, 0x12345678AABBCC.uint64)
  doAssert cast[seq[uint8]](s) == @[204.uint8, 187, 170, 120, 86, 52, 18, 0]
  doAssert s.readUint64(0) == 0x12345678AABBCC.uint64
  echo hexPrint(s)

block:
  var s = ""
  s.addInt8(-12.int8)
  doAssert cast[seq[uint8]](s) == @[244.uint8]
  s = newString(1)
  s.writeInt8(0, -12.int8)
  doAssert cast[seq[uint8]](s) == @[244.uint8]
  doAssert s.readInt8(0) == -12.int8
  echo hexPrint(s)

block:
  var s = ""
  s.addInt16(-1234.int16)
  doAssert cast[seq[uint8]](s) == @[46.uint8, 251]
  s = newString(2)
  s.writeInt16(0, -1234.int16)
  doAssert cast[seq[uint8]](s) == @[46.uint8, 251]
  doAssert s.readInt16(0) == -1234.int16
  echo hexPrint(s)

block:
  var s = ""
  s.addInt32(-12345678.int32)
  doAssert cast[seq[uint8]](s) == @[178.uint8, 158, 67, 255]
  s = newString(4)
  s.writeInt32(0, -12345678.int32)
  doAssert cast[seq[uint8]](s) == @[178.uint8, 158, 67, 255]
  doAssert s.readInt32(0) == -12345678.int32
  echo hexPrint(s)

block:
  var s = ""
  s.addInt64(-123456781234.int64)
  doAssert cast[seq[uint8]](s) == @[78.uint8, 4, 103, 65, 227, 255, 255, 255]
  s = newString(8)
  s.writeInt64(0, -123456781234.int64)
  doAssert cast[seq[uint8]](s) == @[78.uint8, 4, 103, 65, 227, 255, 255, 255]
  doAssert s.readInt64(0) == -123456781234.int64
  echo hexPrint(s)

block:
  var s = ""
  s.addFloat32(-3.25.float32)
  doAssert cast[seq[uint8]](s) == @[0.uint8, 0, 80, 192]
  s = newString(4)
  s.writeFloat32(0, -3.25.float32)
  doAssert cast[seq[uint8]](s) == @[0.uint8, 0, 80, 192]
  doAssert s.readFloat32(0) == -3.25.float32
  echo hexPrint(s)

block:
  var s = ""
  s.addFloat64(-3.25.float64)
  doAssert cast[seq[uint8]](s) == @[0.uint8, 0, 0, 0, 0, 0, 10, 192]
  s = newString(8)
  s.writeFloat64(0, -3.25.float64)
  doAssert cast[seq[uint8]](s) == @[0.uint8, 0, 0, 0, 0, 0, 10, 192]
  doAssert s.readFloat64(0) == -3.25.float64
  echo hexPrint(s)

block:
  doAssert 0x12u8.swap() == 0x12u8
  doAssert 0x3412u16.swap() == 0x1234u16
  doAssert 0x78563412u32.swap() == 0x12345678u32
  when not defined(js):
    doAssert 0xDDCCBBAA78563412u64.swap() == 0x12345678AABBCCDDu64

block:
  let x = true
  doAssert 0x12u8.maybeSwap(x) == 0x12u8
  doAssert 0x3412u16.maybeSwap(x) == 0x1234u16
  doAssert 0x78563412u32.maybeSwap(x) == 0x12345678u32
  when not defined(js):
    doAssert 0xDDCCBBAA78563412u64.maybeSwap(x) == 0x12345678AABBCCDDu64

block:
  let x = false
  doAssert 0x12u8.maybeSwap(x) == 0x12u8
  doAssert 0x3412u16.maybeSwap(x) == 0x3412u16
  doAssert 0x78563412u32.maybeSwap(x) == 0x78563412u32
  when not defined(js):
    doAssert 0xDDCCBBAA78563412u64.maybeSwap(x) == 0xDDCCBBAA78563412u64

block:
  doAssert (-100).int16.swap().swap() == -100
