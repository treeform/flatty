import flatty/memoryused

type
  Test1 = object
    a: uint16
    b: int
    c: array[4, uint8]
    d: float64

  Test2 = ref object
    a: uint32
    b: float
    c: seq[int]
    d: array[4, uint64]

  Test3 = ref object
    a: uint8
    b: Test1

  Test4 = ref object
    a: uint8
    b: Test2

  Test5 = object
    a: (uint64, float64)

  Test6 = ref object
    a: string

block:
  var test: Test1
  doAssert test.memoryUsed() == 2 + 8 + 4 + 8

block:
  var test = Test2()
  test.c.add(1)
  test.c.add(2)
  doAssert test.memoryUsed() == 8 + 4 + 8 + 16 + (2 * 8) + 4 * 8

block:
  var test = Test3()
  doAssert test.memoryUsed() == 8 + 1 + 2 + 8 + 4 + 8

block:
  var test = Test4()
  doAssert test.memoryUsed() == 8 + 1 + 8

block:
  var test: Test5
  doAssert test.memoryUsed() == 8 + 8

block:
  var test = Test6()
  test.a = "test string"
  doAssert test.memoryUsed() == 8 + 16 + 11
