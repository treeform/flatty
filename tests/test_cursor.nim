import std/strutils

import flatty/cursor

block:
  var cursor = initBinaryCursor(
    "\x12\x34\x56\x78\x00\x00\x50\x40hello\x00tail"
  )
  doAssert cursor.readUint8() == 0x12'u8
  doAssert cursor.readUint16Be() == 0x3456'u16
  doAssert cursor.readUint8() == 0x78'u8
  doAssert cursor.readFloat32Le() == 3.25'f32
  doAssert cursor.readCString() == "hello"
  doAssert cursor.readBytes(4) == "tail"
  doAssert cursor.atEnd

block:
  var cursor = initBinaryCursor("\x01\x02\x03\x04payload")
  let header = cursor.readSubcursor(4)
  var readableHeader = header
  doAssert readableHeader.readUint32Le() == 0x04030201'u32
  doAssert readableHeader.atEnd
  doAssert cursor.remaining == 7
  cursor.seek(4)
  cursor.align(4)
  doAssert cursor.readBytes(7) == "payload"

block:
  var cursor = initBinaryCursor("abc")
  try:
    discard cursor.readUint32Le()
    doAssert false
  except BinaryCursorError as error:
    doAssert "only 3 remain" in error.msg

block:
  var cursor = initBinaryCursor("unterminated")
  try:
    discard cursor.readCString(5)
    doAssert false
  except BinaryCursorError as error:
    doAssert "not NUL-terminated" in error.msg

block:
  var cursor = initBinaryCursor("1234")
  try:
    cursor.align(0)
    doAssert false
  except BinaryCursorError:
    discard
