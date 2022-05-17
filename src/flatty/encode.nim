import unicode

proc maybeSwap(u: uint16, swap: bool): uint16 =
  ## Swaps from big endian to little endian if swap is true.
  if swap:
    ((u and 0xFF) shl 8) or ((u and 0xFF00) shr 8)
  else:
    u

proc readUInt16(s: string, i: int): uint16 =
  s[i+0].uint16 +
  s[i+1].uint16 shl 8

proc addUInt16(s: var string, v: uint16) =
  s.add ((v and 0x00FF) shr 0).char
  s.add ((v and 0xFF00) shr 8).char

proc readUInt32(s: string, i: int): uint32 =
  s[i+0].uint32 +
  s[i+1].uint32 shl 8 +
  s[i+2].uint32 shl 16 +
  s[i+3].uint32 shl 24

proc addUInt32(s: var string, v: uint32) =
  s.add ((v and 0x000000FF) shr 0).char
  s.add ((v and 0x0000FF00) shr 8).char
  s.add ((v and 0x00FF0000) shr 16).char
  s.add ((v and 0xFF000000.uint32) shr 24).char

proc toUTF16Inner(input: string, swap: bool, bom: bool): string =
  ## Converts UTF8 to UTF16.
  if bom:
    result.addUInt16(0xFEFF.uint16.maybeSwap(swap))
  for r in input.runes:
    let u = r.uint32
    if (0x0000 <= u and u <= 0xD7FF) or (0xE000 <= u and u <= 0xFFFF):
      result.addUInt16(u.uint16.maybeSwap(swap))
    elif 0x010000 <= u and u <= 0x10FFFF:
      let
        u0 = u - 0x10000
        w1 = 0xD800 + u0 div 0x400
        w2 = 0xDC00 + u0 mod 0x400
      result.addUInt16(w1.uint16.maybeSwap(swap))
      result.addUInt16(w2.uint16.maybeSwap(swap))

proc toUTF16LE*(input: string): string =
  ## Converts UTF8 to UTF16 LE string.
  toUTF16Inner(input, false, false)

proc toUTF16BE*(input: string): string =
  ## Converts UTF8 to UTF16 BE string.
  toUTF16Inner(input, true, false)

proc toUTF16LEWithBom*(input: string): string =
  ## Converts UTF8 to UTF16 LE with byte order mark string.
  toUTF16Inner(input, false, true)

proc toUTF16BEWithBom*(input: string): string =
  ## Converts UTF8 to UTF16 BE with byte order mark string.
  toUTF16Inner(input, true, true)

proc fromUTF16Inner(input: string, i: var int, swap: bool): string =
  ## Converts UTF16 Big Endian to UTF8 string.
  while i + 1 < input.len:
    var u1 = input.readUInt16(i).maybeSwap(swap)
    i += 2
    if u1 - 0xd800 >= 0x800:
      result.add Rune(u1.int)
    else:
      var u2 = input.readUInt16(i).maybeSwap(swap)
      i += 2
      if ((u1 and 0xfc00) == 0xd800) and ((u2 and 0xfc00) == 0xdc00):
        result.add Rune((u1.uint32 shl 10) + u2.uint32 - 0x35fdc00)
      else:
        # Error, produce tofu character.
        result.add "□"

proc fromUTF16*(input: string): string =
  ## Converts UTF16 trying to read byte order marker to UTF8 string.
  if input.len < 2:
    return
  var
    i = 0
    swap: bool = false
  # Deal with Byte Order Mark
  let bom = input.readUInt16(i)
  if bom == 0xFEFF:
    swap = false
    i += 2
  elif bom == 0xFFFE:
    swap = true
    i += 2
  input.fromUTF16Inner(i, swap)

proc fromUTF16BE*(input: string): string =
  ## Converts UTF16 Big Endian to UTF8 string.
  var i = 0
  input.fromUTF16Inner(i, true)

proc fromUTF16LE*(input: string): string =
  ## Converts UTF16 Little Endian to UTF8 string.
  var i = 0
  input.fromUTF16Inner(i, false)

proc toUTF32*(input: string): string =
  ## Converts UTF8 string to utf32.
  for r in input.runes:
    result.addUInt32(r.uint32)

proc fromUTF32*(input: string): string =
  ## Converts utf32 to UTF8 string.
  var i = 0
  while i < input.len:
    result.add Rune(input.readUInt32(i))
    i += 4
