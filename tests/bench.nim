import benchy, bingo, flatty, frosty/streams, jsony, random, streams

type Node = ref object
  active: bool
  kind: string
  name: string
  id: int
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
  if depth > 0:
    for i in 0 .. r.rand(0..3):
      result.kids.add genTree(depth - 1)
    for i in 0 .. r.rand(0..3):
      result.kids.add nil

var tree = genTree(10)
var stringSink: string
var nodeSink: Node
var intSink: int

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

# super slow
# timeIt "std/marshal", 100:
#   keep marshal.`$$`(tree)

timeIt "treeform/jsony", 100:
  stringSink = tree.toJson()
  intSink += stringSink.len

echo "Deserialize speed"

var treeBin = tree.toFlatty()
timeIt "treeform/flatty", 100:
  nodeSink = treeBin.fromFlatty(Node)
  intSink += nodeSink.kids.len

let s = newStringStream()
bingo.storeBin(s, tree)
let bingoBin = s.data
timeIt "bingo/planetis-m binTo", 100:
  let s = newStringStream(bingoBin)
  nodeSink = s.binTo(Node)
  intSink += nodeSink.kids.len

var treeFrosityBin = tree.freeze()
timeIt "disruptek/frosty", 100:
  nodeSink = thaw[Node](treeFrosityBin)
  intSink += nodeSink.kids.len

# super slow
# var treeMarshalBin = $$tree
# timeIt "std/marshal", 100:
#   keep marshal.to[Node](treeMarshalBin)

var treeJsanyBin = tree.toJson()
timeIt "treeform/jsony", 100:
  nodeSink = treeJsanyBin.fromJson(Node)
  intSink += nodeSink.kids.len

echo "sink: ", intSink
