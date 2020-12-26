import flatty, tables

# Test booleans.
doAssert true.toFlatty.fromFlatty(bool) == true
doAssert false.toFlatty.fromFlatty(bool) == false

# Test numbers.
doAssert 123.toFlatty.fromFlatty(int) == 123
doAssert 123.uint8.toFlatty.fromFlatty(uint8) == 123
doAssert 123.uint16.toFlatty.fromFlatty(uint16) == 123
doAssert 123.uint32.toFlatty.fromFlatty(uint32) == 123
doAssert 123.uint64.toFlatty.fromFlatty(uint64) == 123
doAssert 123.int8.toFlatty.fromFlatty(int8) == 123
doAssert 123.int16.toFlatty.fromFlatty(int16) == 123
doAssert 123.int32.toFlatty.fromFlatty(int32) == 123
doAssert 123.int64.toFlatty.fromFlatty(int64) == 123
doAssert 123.456.toFlatty.fromFlatty(float) == 123.456
doAssert $(123.456.float32).toFlatty.fromFlatty(float32) == "123.4560012817383"
doAssert (123.456.float64).toFlatty.fromFlatty(float64) == 123.456

# Test strings.
var str: string
doAssert str.toFlatty.fromFlatty(string) == str
doAssert "".toFlatty.fromFlatty(string) == ""
doAssert "hello world".toFlatty.fromFlatty(string) == "hello world"
doAssert "乾隆己酉夏".toFlatty.fromFlatty(string) == "乾隆己酉夏"
doAssert "\0\0\0\0".toFlatty.fromFlatty(string) == "\0\0\0\0"

# Test arrays.
var seqr: seq[int]
doAssert $(seqr.toFlatty.fromFlatty(seq[int])) == $(seqr)
doAssert $(@[1, 2, 3].toFlatty.fromFlatty(seq[int])) == $(@[1, 2, 3])
doAssert $(@[1.uint8, 2, 3].toFlatty.fromFlatty(seq[uint8])) ==
  $(@[1.uint8, 2, 3])
doAssert $(@["hi", "ho", "hey"].toFlatty.fromFlatty(seq[string])) ==
  $(@["hi", "ho", "hey"])
doAssert $(@[@["hi"], @[], @[]].toFlatty.fromFlatty(seq[seq[string]])) ==
  $(@[@["hi"], @[], @[]])

# Test enums.
type RandomEnum = enum
  Left
  Right
  Top
  Bottom

doAssert Left.toFlatty().fromFlatty(RandomEnum) == Left
doAssert Right.toFlatty().fromFlatty(RandomEnum) == Right
doAssert Top.toFlatty().fromFlatty(RandomEnum) == Top
doAssert Bottom.toFlatty().fromFlatty(RandomEnum) == Bottom

# Test regular objects.
type Foo = object
  id: int
  name: string
  time: float
  active: bool

let foo = Foo(id: 32, name: "yes", time: 16.77, active: true)
doAssert foo.toFlatty().fromFlatty(Foo) == foo

# Test ref objects.
type Bar = ref object
  id: int
  arr: seq[int]
  foo: Foo

var bar = Bar(id: 12)
var bar2 = bar.toFlatty().fromFlatty(Bar)
doAssert bar2 != nil
doAssert bar.id == bar2.id
doAssert bar.arr.len == 0
doAssert bar.foo == Foo()

# Test nested ref objects.
type Node = ref object
  left: Node
  right: Node
var node = Node(left: Node(left: Node()))
var node2 = node.toFlatty().fromFlatty(Node)
doAssert node2.left != nil
doAssert node2.left.left != nil
doAssert node2.left.left.left == nil
doAssert node2.right == nil

# Test distinct objects
type Ts = distinct float64
var ts = Ts(123.123)
func `==`(a, b: TS): bool = float64(a) == float64(b)
doAssert ts.toFlatty.fromFlatty(Ts) == ts

# Test tables
var table: Table[string, string]
table["hi"] = "bye"
table["foo"] = "bar"
doAssert table.toFlatty.fromFlatty(Table[string, string]) == table

# Test arrays
var arr: array[3, int] = [1, 2, 3]
doAssert arr.toFlatty.fromFlatty(array[3, int]) == arr

# Test tuples
var tup: tuple[count: int, id: byte, name: string] = (1, 2.byte, "3")
doAssert tup.toFlatty.fromFlatty(tuple[count: int, id: byte, name: string]) == tup
var tup2: tuple[foo: Foo, id: uint8] = (Foo(), 1.uint8)
doAssert tup2.toFlatty.fromFlatty(tuple[foo: Foo, id: uint8]) == tup2

# Test arrays of tuples (requires forward declarations)
var arrOfTuples: array[2, (int, int)] = [(1, 2), (0, 3)]
doAssert arrOfTuples.toFlatty.fromFlatty(array[2, (int, int)]) == arrOfTuples
