import flatty

type
  ModeObj = object
    a: int
    b: uint
    c: int16

  ModeTuple = tuple
    a: int
    b: uint8
    c: uint

const FlattyModeIntSize =
  when defined(flatty32):
    4
  elif defined(flatty64):
    8
  else:
    sizeof(int)

doAssert 1.toFlatty.len == FlattyModeIntSize
doAssert 1.uint.toFlatty.len == FlattyModeIntSize

doAssert "abc".toFlatty.len == FlattyModeIntSize + 3
doAssert @[1.uint8, 2, 3].toFlatty.len == FlattyModeIntSize + 3

let modeObj = ModeObj(a: 1, b: 2.uint, c: 3.int16)
let modeTuple: ModeTuple = (a: 1, b: 2.uint8, c: 3.uint)

doAssert @[1, 2, 3].toFlatty.len == FlattyModeIntSize + 3 * FlattyModeIntSize
doAssert [1, 2, 3].toFlatty.len == 3 * FlattyModeIntSize
doAssert modeObj.toFlatty.len == 2 * FlattyModeIntSize + 2
doAssert modeTuple.toFlatty.len == 2 * FlattyModeIntSize + 1

doAssert 1.toFlatty.fromFlatty(int) == 1
doAssert 1.uint.toFlatty.fromFlatty(uint) == 1.uint
doAssert "abc".toFlatty.fromFlatty(string) == "abc"
doAssert @[1, 2, 3].toFlatty.fromFlatty(seq[int]) == @[1, 2, 3]
doAssert [1, 2, 3].toFlatty.fromFlatty(array[3, int]) == [1, 2, 3]
doAssert modeObj.toFlatty.fromFlatty(ModeObj) == modeObj
doAssert modeTuple.toFlatty.fromFlatty(ModeTuple) == modeTuple
