import benchy, random, flatty, frosty, marshal, bingod, streams

type Node = ref object
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
  result.name = "node" & $result.id
  result.kind = "NODE"
  if depth > 0:
    for i in 0 .. r.rand(0..3):
      result.kids.add genTree(depth - 1)

var tree = genTree(12)

echo genId, " node tree:"

timeIt "treeform/flatty toFlatty":
  keep tree.toFlatty()

var treeBin = tree.toFlatty()
timeIt "treeform/flatty fromFlatty":
  keep treeBin.fromFlatty(Node)

timeIt "bingod/planetis-m ":
  let s = newStringStream()
  bingod.storeBin(s, tree)
  s.setPosition(0)
  keep s.readAll()

let s = newStringStream()
bingod.storeBin(s, tree)
s.setPosition(0)
let bingodBin = s.readAll()
timeIt "bingod/planetis-m":
  let s = newStringStream(bingodBin)
  keep s.binTo(Node)

timeIt "disruptek/frosty freeze":
  keep tree.freeze()

var treeFrosityBin = tree.freeze()
timeIt "disruptek/frosty thaw":
  keep thaw[Node](treeFrosityBin)

timeIt "std/marshal $$":
  keep marshal.`$$`(tree)

var treeMarshalBin = $$tree
timeIt "std/marshal to":
  keep marshal.to[Node](treeMarshalBin)
