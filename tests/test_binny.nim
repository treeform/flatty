import flatty/binny, flatty/hexPrint, streams, strutils

block:
  var s = ""
  s.addUint8(0x12.uint8)
  echo hexPrint(s)
  doAssert s.readUint8(0) == 0x12.uint8

  var ss = newStringStream()
  ss.write(0x12.uint8)
  ss.setPosition(0)
  doAssert ss.readAll() == s

  var s2 = newString(1)
  s2.writeUint8(0, 0x12.uint8)
  doAssert s2.readUint8(0) == 0x12.uint8

block:
  var s = ""
  s.addUint16(0x1234.uint16)
  echo hexPrint(s)
  doAssert s.readUint16(0) == 0x1234.uint16

  var ss = newStringStream()
  ss.write(0x1234.uint16)
  ss.setPosition(0)
  doAssert ss.readAll() == s

  var s2 = newString(2)
  s2.writeUint16(0, 0x1234.uint16)
  doAssert s2.readUint16(0) == 0x1234.uint16

block:
  var s = ""
  s.addUint32(0x12345678.uint32)
  echo hexPrint(s)
  doAssert s.readUint32(0) == 0x12345678.uint32

  var ss = newStringStream()
  ss.write(0x12345678.uint32)
  ss.setPosition(0)
  doAssert ss.readAll() == s

  var s2 = newString(4)
  s2.writeUint32(0, 0x12345678.uint32)
  doAssert s2.readUint32(0) == 0x12345678.uint32

block:
  var s = ""
  s.addUint64(0x12345678AABBCC.uint64)
  echo hexPrint(s)
  doAssert s.readUint64(0) == 0x12345678AABBCC.uint64

  var ss = newStringStream()
  ss.write(0x12345678AABBCC.uint64)
  ss.setPosition(0)
  doAssert ss.readAll() == s

  var s2 = newString(8)
  s2.writeUint64(0, 0x12345678AABBCC.uint64)
  doAssert s2.readUint64(0) == 0x12345678AABBCC.uint64

block:
  var s = ""
  s.addInt8(-12.int8)
  doAssert s.readInt8(0) == -12.int8

block:
  var s = ""
  s.addInt16(-1234.int16)
  doAssert s.readInt16(0) == -1234.int16

block:
  var s = ""
  s.addInt32(-12345678.int32)
  doAssert s.readInt32(0) == -12345678.int32

block:
  var s = ""
  s.addInt64(-123456781234.int64)
  doAssert s.readInt64(0) == -123456781234.int64

block:
  var s = ""
  s.addFloat32(-3.14.float32)
  doAssert s.readFloat32(0) == -3.14.float32

block:
  var s = ""
  s.addFloat64(-3.14.float64)
  doAssert s.readFloat64(0) == -3.14.float64

block:
  doAssert 0x12u8.swap() == 0x12u8
  doAssert 0x3412u16.swap() == 0x1234u16
  doAssert 0x78563412u32.swap() == 0x12345678u32
  doAssert 0xDDCCBBAA78563412u64.swap() == 0x12345678AABBCCDDu64

block:
  let x = true
  doAssert 0x12u8.maybeSwap(x) == 0x12u8
  doAssert 0x3412u16.maybeSwap(x) == 0x1234u16
  doAssert 0x78563412u32.maybeSwap(x) == 0x12345678u32
  doAssert 0xDDCCBBAA78563412u64.maybeSwap(x) == 0x12345678AABBCCDDu64

block:
  let x = false
  doAssert 0x12u8.maybeSwap(x) == 0x12u8
  doAssert 0x3412u16.maybeSwap(x) == 0x3412u16
  doAssert 0x78563412u32.maybeSwap(x) == 0x78563412u32
  doAssert 0xDDCCBBAA78563412u64.maybeSwap(x) == 0xDDCCBBAA78563412u64

block:
  doAssert (-100).int16.swap().swap() == -100
