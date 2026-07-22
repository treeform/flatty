## Bounds-checked sequential reads over an in-memory binary blob.
##
## `binny` is ideal for fixed-offset primitive reads. `BinaryCursor` adds a
## small amount of state for parsers that consume fields in order and need
## catchable errors at an untrusted-input boundary.

import flatty/binny

type
  BinaryCursorError* = object of CatchableError

  BinaryCursor* = object
    data: string
    position*: int

proc fail(message: string) {.noreturn.} =
  raise newException(BinaryCursorError, message)

proc initBinaryCursor*(data: sink string; position = 0): BinaryCursor =
  ## Creates a cursor over `data`, initially positioned at `position`.
  if position < 0 or position > data.len:
    fail("binary cursor position is outside the input")
  BinaryCursor(data: move(data), position: position)

proc len*(cursor: BinaryCursor): int {.inline.} =
  ## Returns the total byte length of the cursor input.
  cursor.data.len

proc remaining*(cursor: BinaryCursor): int {.inline.} =
  ## Returns the number of unread bytes.
  cursor.data.len - cursor.position

proc atEnd*(cursor: BinaryCursor): bool {.inline.} =
  ## Returns true when no unread bytes remain.
  cursor.position == cursor.data.len

proc require*(cursor: BinaryCursor; count: int) =
  ## Ensures that `count` bytes can be consumed from the current position.
  if count < 0 or count > cursor.remaining:
    fail(
      "binary cursor needs " & $count & " bytes at " & $cursor.position &
        ", but only " & $cursor.remaining & " remain"
    )

proc seek*(cursor: var BinaryCursor; position: int) =
  ## Moves the cursor to an absolute byte position.
  if position < 0 or position > cursor.data.len:
    fail("binary cursor seek is outside the input")
  cursor.position = position

proc skip*(cursor: var BinaryCursor; count: int) =
  ## Advances the cursor by `count` bytes.
  cursor.require(count)
  cursor.position += count

proc align*(cursor: var BinaryCursor; alignment: int) =
  ## Advances to the next `alignment` byte boundary.
  if alignment <= 0:
    fail("binary cursor alignment must be positive")
  let remainder = cursor.position mod alignment
  if remainder != 0:
    cursor.skip(alignment - remainder)

proc readBytes*(cursor: var BinaryCursor; count: int): string =
  ## Reads exactly `count` bytes.
  cursor.require(count)
  result = cursor.data[cursor.position ..< cursor.position + count]
  cursor.position += count

proc readCString*(cursor: var BinaryCursor; maxBytes = -1): string =
  ## Reads a NUL-terminated string, optionally bounded by `maxBytes`.
  if maxBytes < -1:
    fail("binary cursor string bound cannot be negative")
  let limit =
    if maxBytes == -1:
      cursor.data.len
    else:
      cursor.position + min(maxBytes, cursor.remaining)
  var stop = cursor.position
  while stop < limit and cursor.data[stop] != '\0':
    inc stop
  if stop == limit:
    fail("binary cursor string is not NUL-terminated within its bound")
  result = cursor.data[cursor.position ..< stop]
  cursor.position = stop + 1

proc readSubcursor*(cursor: var BinaryCursor; count: int): BinaryCursor =
  ## Reads a bounded region and returns a cursor over that region.
  initBinaryCursor(cursor.readBytes(count))

proc readUint8*(cursor: var BinaryCursor): uint8 =
  cursor.require(1)
  result = cursor.data.readUint8(cursor.position)
  inc cursor.position

proc readUint16Le*(cursor: var BinaryCursor): uint16 =
  cursor.require(2)
  result = cursor.data.readUint16(cursor.position)
  cursor.position += 2

proc readUint16Be*(cursor: var BinaryCursor): uint16 =
  cursor.readUint16Le().swap()

proc readUint32Le*(cursor: var BinaryCursor): uint32 =
  cursor.require(4)
  result = cursor.data.readUint32(cursor.position)
  cursor.position += 4

proc readUint32Be*(cursor: var BinaryCursor): uint32 =
  cursor.readUint32Le().swap()

proc readUint64Le*(cursor: var BinaryCursor): uint64 =
  cursor.require(8)
  result = cursor.data.readUint64(cursor.position)
  cursor.position += 8

proc readUint64Be*(cursor: var BinaryCursor): uint64 =
  cursor.readUint64Le().swap()

proc readInt8*(cursor: var BinaryCursor): int8 =
  cast[int8](cursor.readUint8())

proc readInt16Le*(cursor: var BinaryCursor): int16 =
  cast[int16](cursor.readUint16Le())

proc readInt16Be*(cursor: var BinaryCursor): int16 =
  cast[int16](cursor.readUint16Be())

proc readInt32Le*(cursor: var BinaryCursor): int32 =
  cast[int32](cursor.readUint32Le())

proc readInt32Be*(cursor: var BinaryCursor): int32 =
  cast[int32](cursor.readUint32Be())

proc readInt64Le*(cursor: var BinaryCursor): int64 =
  cast[int64](cursor.readUint64Le())

proc readInt64Be*(cursor: var BinaryCursor): int64 =
  cast[int64](cursor.readUint64Be())

proc readFloat32Le*(cursor: var BinaryCursor): float32 =
  cast[float32](cursor.readUint32Le())

proc readFloat32Be*(cursor: var BinaryCursor): float32 =
  cast[float32](cursor.readUint32Be())

proc readFloat64Le*(cursor: var BinaryCursor): float64 =
  cast[float64](cursor.readUint64Le())

proc readFloat64Be*(cursor: var BinaryCursor): float64 =
  cast[float64](cursor.readUint64Be())
