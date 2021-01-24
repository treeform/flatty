import benchy, bingod, flatty, frosty, jsony, marshal, random, streams

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

echo genId, " node tree:"

echo "Serialize speed"
timeIt "treeform/flatty", 100:
  keep tree.toFlatty()

timeIt "bingod/planetis-m", 100:
  let s = newStringStream()
  bingod.storeBin(s, tree)
  keep s.data

timeIt "disruptek/frosty", 100:
  keep tree.freeze()

# super slow
# timeIt "std/marshal", 100:
#   keep marshal.`$$`(tree)

timeIt "treeform/jsony", 100:
  keep tree.toJson()

echo "Deserialize speed"

var treeBin = tree.toFlatty()
timeIt "treeform/flatty", 100:
  keep treeBin.fromFlatty(Node)

let s = newStringStream()
bingod.storeBin(s, tree)
let bingodBin = s.data
timeIt "bingod/planetis-m binTo", 100:
  let s = newStringStream(bingodBin)
  keep s.binTo(Node)

var treeFrosityBin = tree.freeze()
timeIt "disruptek/frosty", 100:
  keep thaw[Node](treeFrosityBin)

# super slow
# var treeMarshalBin = $$tree
# timeIt "std/marshal", 100:
#   keep marshal.to[Node](treeMarshalBin)

var treeJsanyBin = tree.toJson()
timeIt "treeform/jsony", 100:
  keep treeJsanyBin.fromJson(Node)
