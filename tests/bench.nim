import benchy, bingo, flatty, frosty/streams, jsony, marshal, random, streams

type Node = ref object
  active: bool
  kind: string
  name: string
  id: int
  payload: string
  u16s: array[32, uint16]
  u64s: array[16, uint64]
  kids: seq[Node]

var r = initRand(2020)
var genId: int
proc genTree(depth: int): Node =
  result = Node()
  result.id = genId
  inc genId
  if r.rand(0 .. 1) == 0:
    result.active = true
  result.name = "node" & $result.id
  result.kind = "NODE"
  result.payload =
    "payload-" & $result.id &
    "-abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  for i in 0 .. result.u16s.high:
    result.u16s[i] = uint16((result.id * 17 + i) and 0xffff)
  for i in 0 .. result.u64s.high:
    result.u64s[i] = uint64(result.id) * 1_000_003'u64 + uint64(i)
  if depth > 0:
    for i in 0 .. r.rand(0..3):
      result.kids.add genTree(depth - 1)
    for i in 0 .. r.rand(0..3):
      result.kids.add nil

var stringSink: string
var nodeSink: Node
var intSink: int

var tree = genTree(10)

echo genId, " node tree:"

echo "Serialize speed"
timeIt "treeform/flatty", 100:
  stringSink = tree.toFlatty()
  intSink += stringSink.len

timeIt "bingo/planetis-m", 100:
  let s = newStringStream()
  bingo.storeBin(s, tree)
  stringSink = s.data
  intSink += stringSink.len

timeIt "disruptek/frosty", 100:
  stringSink = tree.freeze()
  intSink += stringSink.len

timeIt "std/marshal", 100:
  stringSink = marshal.`$$`(tree)
  intSink += stringSink.len

timeIt "treeform/jsony", 100:
  stringSink = tree.toJson()
  intSink += stringSink.len

echo "Deserialize speed"

var treeBin = tree.toFlatty()
timeIt "treeform/flatty", 100:
  nodeSink = treeBin.fromFlatty(Node)
  intSink += nodeSink.kids.len + nodeSink.payload.len + int(nodeSink.u16s[0])

let s = newStringStream()
bingo.storeBin(s, tree)
let bingoBin = s.data
timeIt "bingo/planetis-m binTo", 100:
  let s = newStringStream(bingoBin)
  nodeSink = s.binTo(Node)
  intSink += nodeSink.kids.len + nodeSink.payload.len + int(nodeSink.u16s[0])

var treeFrosityBin = tree.freeze()
timeIt "disruptek/frosty", 100:
  nodeSink = thaw[Node](treeFrosityBin)
  intSink += nodeSink.kids.len + nodeSink.payload.len + int(nodeSink.u16s[0])

var treeMarshalBin = marshal.`$$`(tree)
timeIt "std/marshal", 100:
  nodeSink = marshal.to[Node](treeMarshalBin)
  intSink += nodeSink.kids.len + nodeSink.payload.len + int(nodeSink.u16s[0])

var treeJsanyBin = tree.toJson()
timeIt "treeform/jsony", 100:
  nodeSink = treeJsanyBin.fromJson(Node)
  intSink += nodeSink.kids.len + nodeSink.payload.len + int(nodeSink.u16s[0])

echo "sink: ", intSink
