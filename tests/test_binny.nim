import flatty/binny, flatty/hexPrint, streams, strutils

block:
  var s = ""
  s.addUInt8(0x12.uint8)
  echo hexPrint(s)
  assert s.readUint8(0) == 0x12.uint8

  var ss = newStringStream()
  ss.write(0x12.uint8)
  ss.setPosition(0)
  assert ss.readAll() == s

  var s2 = newString(1)
  s2.writeUInt8(0, 0x12.uint8)
  assert s2.readUint8(0) == 0x12.uint8

block:
  var s = ""
  s.addUInt16(0x1234.uint16)
  echo hexPrint(s)
  assert s.readUint16(0) == 0x1234.uint16

  var ss = newStringStream()
  ss.write(0x1234.uint16)
  ss.setPosition(0)
  assert ss.readAll() == s

  var s2 = newString(2)
  s2.writeUInt16(0, 0x1234.uint16)
  assert s2.readUint16(0) == 0x1234.uint16

block:
  var s = ""
  s.addUInt32(0x12345678.uint32)
  echo hexPrint(s)
  assert s.readUint32(0) == 0x12345678.uint32

  var ss = newStringStream()
  ss.write(0x12345678.uint32)
  ss.setPosition(0)
  assert ss.readAll() == s

  var s2 = newString(4)
  s2.writeUInt32(0, 0x12345678.uint32)
  assert s2.readUint32(0) == 0x12345678.uint32

block:
  var s = ""
  s.addUInt64(0x12345678AABBCC.uint64)
  echo hexPrint(s)
  assert s.readUint64(0) == 0x12345678AABBCC.uint64

  var ss = newStringStream()
  ss.write(0x12345678AABBCC.uint64)
  ss.setPosition(0)
  assert ss.readAll() == s

  var s2 = newString(8)
  s2.writeUInt64(0, 0x12345678AABBCC.uint64)
  assert s2.readUint64(0) == 0x12345678AABBCC.uint64

block:
  var s = ""
  s.addInt8(-12.int8)
  assert s.readInt8(0) == -12.int8

block:
  var s = ""
  s.addInt16(-1234.int16)
  assert s.readInt16(0) == -1234.int16

block:
  var s = ""
  s.addInt32(-12345678.int32)
  assert s.readInt32(0) == -12345678.int32

block:
  var s = ""
  s.addInt64(-123456781234.int64)
  assert s.readInt64(0) == -123456781234.int64

block:
  var s = ""
  s.addFloat32(-3.14.float32)
  assert s.readFloat32(0) == -3.14.float32

block:
  var s = ""
  s.addFloat64(-3.14.float64)
  assert s.readFloat64(0) == -3.14.float64

block:
  assert 0x12u8.swap() == 0x12u8
  assert 0x3412u16.swap() == 0x1234u16
  assert 0x78563412u32.swap() == 0x12345678u32
  assert 0xDDCCBBAA78563412u64.swap() == 0x12345678AABBCCDDu64

block:
  let x = true
  assert 0x12u8.maybeSwap(x) == 0x12u8
  assert 0x3412u16.maybeSwap(x) == 0x1234u16
  assert 0x78563412u32.maybeSwap(x) == 0x12345678u32
  assert 0xDDCCBBAA78563412u64.maybeSwap(x) == 0x12345678AABBCCDDu64

block:
  let x = false
  assert 0x12u8.maybeSwap(x) == 0x12u8
  assert 0x3412u16.maybeSwap(x) == 0x3412u16
  assert 0x78563412u32.maybeSwap(x) == 0x78563412u32
  assert 0xDDCCBBAA78563412u64.maybeSwap(x) == 0xDDCCBBAA78563412u64
