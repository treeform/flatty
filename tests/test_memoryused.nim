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
  doAssert test.memoryUsed() ==
    sizeof(uint16) + sizeof(int) + 4 * sizeof(uint8) + sizeof(float64)

block:
  var test = Test2()
  test.c.add(1)
  test.c.add(2)
  doAssert test.memoryUsed() ==
    sizeof(test) + sizeof(uint32) + sizeof(float) + 16 +
    test.c.len * sizeof(int) + 4 * sizeof(uint64)

block:
  var test = Test3()
  doAssert test.memoryUsed() ==
    sizeof(test) + sizeof(uint8) +
    sizeof(uint16) + sizeof(int) + 4 * sizeof(uint8) + sizeof(float64)

block:
  var test = Test4()
  doAssert test.memoryUsed() == sizeof(test) + sizeof(uint8) + sizeof(Test2)

block:
  var test: Test5
  doAssert test.memoryUsed() == sizeof(uint64) + sizeof(float64)

block:
  var test = Test6()
  test.a = "test string"
  doAssert test.memoryUsed() == sizeof(test) + 16 + test.a.len
