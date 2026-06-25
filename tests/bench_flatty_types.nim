import benchy, flatty, std/[sets, tables]

const
  IntArrayLen = 524288
  NumSeqLen = 500000
  StringLen = 1048576
  StringSeqLen = 12000
  CopyObjLen = 196608
  MixedObjLen = 4000
  TupleLen = 4096
  TableLen = 3000
  TreeDepth = 7
  TreeFanout = 3

type
  UserId = distinct uint64

  CopyObj = object
    id: uint64
    score: float64
    flags: uint32

  MixedObj = object
    id: int
    name: string
    values: seq[int32]

  MixedTuple = tuple[id: UserId, label: string, values: array[8, float64]]

  Node = ref object
    id: int
    name: string
    kids: seq[Node]

var bytesSink: string
var intSink: int

proc useBytes(s: string) {.inline.} =
  bytesSink = s
  intSink = intSink xor bytesSink.len
  if bytesSink.len > 0:
    intSink = intSink xor ord(bytesSink[0]) xor ord(bytesSink[^1])

template benchCase(label: string, valueExpr, typ, sinkVar, touchExpr: untyped) =
  block:
    let bin = valueExpr.toFlatty()
    echo label, " payload bytes: ", bin.len

    timeIt label & " toFlatty", 100:
      useBytes(valueExpr.toFlatty())

    timeIt label & " fromFlatty", 100:
      sinkVar = bin.fromFlatty(typ)
      intSink = intSink xor touchExpr

proc makeIntArray(): array[IntArrayLen, int64] =
  for i in 0 .. result.high:
    result[i] = int64(i * 17 - 3000)

proc makeIntSeq(): seq[int64] =
  result = newSeq[int64](NumSeqLen)
  for i in 0 .. result.high:
    result[i] = int64(i * 13 - 7000)

proc makeFloatSeq(): seq[float64] =
  result = newSeq[float64](NumSeqLen)
  for i in 0 .. result.high:
    result[i] = float64(i) / 3.25

proc makeString(): string =
  result = newStringOfCap(StringLen)
  for i in 0 ..< StringLen:
    result.add char(ord('a') + (i mod 26))

proc makeStringSeq(): seq[string] =
  result = newSeq[string](StringSeqLen)
  for i in 0 .. result.high:
    result[i] = "name-" & $i & "-value-" & $(i * i)

proc makeCopyObjects(): array[CopyObjLen, CopyObj] =
  for i in 0 .. result.high:
    result[i] = CopyObj(
      id: uint64(i),
      score: float64(i) / 9.5,
      flags: uint32(i mod 32)
    )

proc makeMixedObjects(): seq[MixedObj] =
  result = newSeq[MixedObj](MixedObjLen)
  for i in 0 .. result.high:
    result[i] = MixedObj(
      id: i,
      name: "record-" & $i,
      values: @[int32(i), int32(i + 1), int32(i + 2), int32(i + 3)]
    )

proc makeTuples(): array[TupleLen, MixedTuple] =
  for i in 0 .. result.high:
    result[i].id = UserId(uint64(i))
    result[i].label = "tuple-" & $i
    for j in 0 .. result[i].values.high:
      result[i].values[j] = float64(i * j)

proc makeTable(): Table[string, int] =
  for i in 0 ..< TableLen:
    result["key-" & $i] = i * 3

proc makeSet(): HashSet[string] =
  for i in 0 ..< TableLen:
    result.incl "set-" & $i

proc makeTree(depth, fanout: int, nextId: var int): Node =
  result = Node(id: nextId, name: "node-" & $nextId)
  inc nextId
  if depth > 0:
    for _ in 0 ..< fanout:
      result.kids.add makeTree(depth - 1, fanout, nextId)

var
  intArray = makeIntArray()
  intSeq = makeIntSeq()
  floatSeq = makeFloatSeq()
  longString = makeString()
  stringSeq = makeStringSeq()
  copyObjects = makeCopyObjects()
  mixedObjects = makeMixedObjects()
  mixedTuples = makeTuples()
  stringTable = makeTable()
  stringSet = makeSet()
  nextNodeId = 0
  tree = makeTree(TreeDepth, TreeFanout, nextNodeId)

var
  intArraySink: array[IntArrayLen, int64]
  intSeqSink: seq[int64]
  floatSeqSink: seq[float64]
  longStringSink: string
  stringSeqSink: seq[string]
  copyObjectsSink: array[CopyObjLen, CopyObj]
  mixedObjectsSink: seq[MixedObj]
  mixedTuplesSink: array[TupleLen, MixedTuple]
  stringTableSink: Table[string, int]
  stringSetSink: HashSet[string]
  treeSink: Node

echo "Flatty type-shape benchmark"
echo "Serialize and deserialize speed"

benchCase(
  "array[int64]",
  intArray,
  array[IntArrayLen, int64],
  intArraySink,
  int(intArraySink[0] xor intArraySink[^1])
)

benchCase(
  "seq[int64]",
  intSeq,
  seq[int64],
  intSeqSink,
  intSeqSink.len
)

benchCase(
  "seq[float64]",
  floatSeq,
  seq[float64],
  floatSeqSink,
  floatSeqSink.len
)

benchCase(
  "string",
  longString,
  string,
  longStringSink,
  longStringSink.len
)

benchCase(
  "seq[string]",
  stringSeq,
  seq[string],
  stringSeqSink,
  stringSeqSink.len
)

benchCase(
  "array[CopyObj]",
  copyObjects,
  array[CopyObjLen, CopyObj],
  copyObjectsSink,
  int(copyObjectsSink[0].id xor copyObjectsSink[^1].id)
)

benchCase(
  "seq[MixedObj]",
  mixedObjects,
  seq[MixedObj],
  mixedObjectsSink,
  mixedObjectsSink.len
)

benchCase(
  "array[MixedTuple]",
  mixedTuples,
  array[TupleLen, MixedTuple],
  mixedTuplesSink,
  int(uint64(mixedTuplesSink[0].id) xor uint64(mixedTuplesSink[^1].id))
)

benchCase(
  "Table[string, int]",
  stringTable,
  Table[string, int],
  stringTableSink,
  stringTableSink.len
)

benchCase(
  "HashSet[string]",
  stringSet,
  HashSet[string],
  stringSetSink,
  stringSetSink.len
)

benchCase(
  "ref object tree",
  tree,
  Node,
  treeSink,
  treeSink.kids.len
)

echo "sink: ", intSink
