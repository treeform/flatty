import flatty, intsets, json, tables, sets, flatty/hexprint

# Test booleans.
doAssert true.toFlatty.fromFlatty(bool) == true
doAssert false.toFlatty.fromFlatty(bool) == false

# Test chars.
doAssert 'a'.toFlatty.fromFlatty(char) == 'a'
doAssert 'z'.toFlatty.fromFlatty(char) == 'z'
doAssert '\0'.toFlatty.fromFlatty(char) == '\0'
doAssert '\n'.toFlatty.fromFlatty(char) == '\n'

# Test numbers.
doAssert 123.toFlatty.fromFlatty(int) == 123
doAssert 123.uint.toFlatty.fromFlatty(uint) == 123
doAssert 123.uint8.toFlatty.fromFlatty(uint8) == 123
doAssert 123.uint16.toFlatty.fromFlatty(uint16) == 123
doAssert 123.uint32.toFlatty.fromFlatty(uint32) == 123
doAssert 123.uint64.toFlatty.fromFlatty(uint64) == 123
doAssert 123.int8.toFlatty.fromFlatty(int8) == 123
doAssert 123.int16.toFlatty.fromFlatty(int16) == 123
doAssert 123.int32.toFlatty.fromFlatty(int32) == 123
doAssert 123.int64.toFlatty.fromFlatty(int64) == 123

doAssert 123.25.toFlatty.fromFlatty(float) == 123.25
doAssert $(123.25.float32).toFlatty.fromFlatty(float32) == "123.25"
doAssert (123.25.float64).toFlatty.fromFlatty(float64) == 123.25

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
func `==`(a, b: Ts): bool = float64(a) == float64(b)
doAssert ts.toFlatty.fromFlatty(Ts) == ts

# Test tables
block:
  var table: Table[string, string]
  table["hi"] = "bye"
  table["foo"] = "bar"
  doAssert table.toFlatty.fromFlatty(Table[string, string]) == table

block:
  var table: OrderedTable[string, string]
  table["hi"] = "bye"
  table["foo"] = "bar"
  doAssert table.toFlatty.fromFlatty(OrderedTable[string, string]) == table

block:
  var table: CountTable[string]
  table.inc("hi")
  table.inc("hi")
  table.inc("foo")
  doAssert table.toFlatty.fromFlatty(type(table)) == table

block:
  var table: TableRef[string, string]
  new(table)
  table["hi"] = "bye"
  table["foo"] = "bar"
  doAssert table.toFlatty.fromFlatty(type(table)) == table

block:
  var table: OrderedTableRef[string, string]
  new(table)
  table["hi"] = "bye"
  table["foo"] = "bar"
  doAssert table.toFlatty.fromFlatty(type(table)) == table

block:
  var table: CountTableRef[string]
  new(table)
  table.inc("hi")
  table.inc("hi")
  table.inc("foo")
  doAssert table.toFlatty.fromFlatty(type(table)) == table


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

when not defined(js):
  # Test intsets
  var intSet = initIntSet()
  for i in 0 .. 10:
    intSet.incl i
  doAssert intSet.toFlatty.fromFlatty(type(intSet)) == intSet

# Test OOP
type
  Person = ref object of RootObj
    name*: string # the * means that `name` is accessible from other modules
    age: int      # no * means that the field is hidden from other modules

  Student = ref object of Person # Student inherits from Person
    id: int
var
  student: Student
  person: Person
doAssert student.toFlatty.fromFlatty(type(student)) == student
doAssert person.toFlatty.fromFlatty(type(person)) == person

# Test Object variants
type
  NodeNumKind = enum # the different node types
    nkInt,           # a leaf with an integer value
    nkFloat,         # a leaf with a float value
  RefNode = ref object
    active: bool
    case kind: NodeNumKind # the ``kind`` field is the discriminator
    of nkInt: intVal: int
    of nkFloat: floatVal: float

  ValueNode = object
    active: bool
    case kind: NodeNumKind # the ``kind`` field is the discriminator
    of nkInt: intVal: int
    of nkFloat: floatVal: float

block:
  var nodeNum = RefNode(kind: nkFloat, active: true, floatVal: 3.14)
  var nodeNum2 = RefNode(kind: nkInt, active: false, intVal: 42)

  doAssert nodeNum.toFlatty.fromFlatty(type(nodeNum)).floatVal ==
      nodeNum.floatVal
  doAssert nodeNum2.toFlatty.fromFlatty(type(nodeNum2)).intVal ==
      nodeNum2.intVal
  doAssert nodeNum.toFlatty.fromFlatty(type(nodeNum)).active == nodeNum.active
  doAssert nodeNum2.toFlatty.fromFlatty(type(nodeNum2)).active ==
      nodeNum2.active

block:
  var nodeNum = ValueNode(kind: nkFloat, active: true, floatVal: 3.14)
  var nodeNum2 = ValueNode(kind: nkInt, active: false, intVal: 42)

  doAssert nodeNum.toFlatty.fromFlatty(type(nodeNum)).floatVal ==
      nodeNum.floatVal
  doAssert nodeNum2.toFlatty.fromFlatty(type(nodeNum2)).intVal ==
      nodeNum2.intVal
  doAssert nodeNum.toFlatty.fromFlatty(type(nodeNum)).active == nodeNum.active
  doAssert nodeNum2.toFlatty.fromFlatty(type(nodeNum2)).active ==
      nodeNum2.active

var jsonNode = parseJson("{\"json\": true, \"count\":20}")
doAssert jsonNode.toFlatty.fromFlatty(type(jsonNode)) == jsonNode

# Enum indexed array
block:
  type Colors = enum
    red, green, yellow, blue
  let a = [
    red: 100,
    green: 300,
    yellow: -100,
    blue: 42
  ]
  doAssert a.toFlatty.fromFlatty(a.typeof) == a

# Complex object
block:
  type Side = enum
    left, right
  type
    SubObject = object
      a: int64
      b: string
    BigObject = object
      subs: seq[SubObject]
      arr: array[Side, SubObject]
  let a = BigObject(
    subs: @[
      SubObject(a: 100, b: "Hmm"),
      SubObject(a: 20, b: "Heh")
    ],
    arr: [
      left: SubObject(a: 42, b: "Ahhh"),
      right: SubObject(a: 31415, b: "Pi")
    ]
  )
  doAssert a.toFlatty.fromFlatty(a.type) == a

block:
  # https://github.com/treeform/flatty/issues/22
  type
    Direction = enum North, South, East, West
    DirRange = range[North..West]
    RangeT = range[1..10]
    RangeU = range[1.0..10.0]
    Thing = object
      name: string
      X: RangeT
      Y: RangeU
      Z: DirRange

  var aDirection = North
  doAssert toFlatty(aDirection).fromFlatty(Direction) == aDirection

  var aDirRange = DirRange(North)
  doAssert toFlatty(aDirRange).fromFlatty(DirRange) == aDirRange

  var aRangeT = RangeT(2)
  doAssert toFlatty(aRangeT).fromFlatty(RangeT) == aRangeT

  var aRangeU = RangeU(3.14)
  doAssert toFlatty(aRangeU).fromFlatty(RangeU) == aRangeU

  let u = @[
    Thing(name: "hi", X: 1.RangeT, Y: 1.0.RangeU, Z: North.DirRange),
    Thing(name: "bye", X: 2.RangeT, Y: 2.0.RangeU, Z: West.DirRange)
  ]
  let binaryData = toFlatty(u)
  let u2 = binaryData.fromFlatty(seq[Thing])

  doAssert u2[0].X == 1
  doAssert u2[0].Y == 1.0
  doAssert u2[0].Z == North
  doAssert u2[1].X == 2
  doAssert u2[1].Y == 2.0
  doAssert u2[1].Z == West

block:
  # Sets
  # set is too large???
  # doAssert {1, 2, 3}.toFlatty.fromFlatty(set[int]) == {1, 2, 3}
  doAssert {'a'..'z'}.toFlatty.fromFlatty(set[char]) == {'a'..'z'}
  doAssert {1.uint8, 2.uint8}.toFlatty.fromFlatty(set[uint8]) == {1.uint8, 2.uint8}
  doAssert {1.uint16, 2.uint16}.toFlatty.fromFlatty(set[uint16]) == {1.uint16, 2.uint16}

  let hSet1 = toHashSet(["dog", "cat"])
  doAssert hSet1.toFlatty.fromFlatty(HashSet[string]) == hSet1
  let hSet2 = toOrderedSet(["dog", "cat"])
  doAssert hSet2.toFlatty.fromFlatty(OrderedSet[string]) == hSet2

  let hSet3 = toHashSet([1.1, 2.2, 3.3])
  doAssert hSet3.toFlatty.fromFlatty(HashSet[float64]) == hSet3
  let hSet4 = toOrderedSet([1.1, 2.2, 3.3])
  doAssert hSet4.toFlatty.fromFlatty(OrderedSet[float64]) == hSet4

echo "DONE"
