import benchy, random

import flatty/memoryused
import flatty/hashy2# flatty

type Trap = object
  top: float64
  bottom: float64
  height: float64

type Node = ref object
  active: bool
  t: Trap
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

echo genId, " node tree"
echo memoryused(tree)


# timeIt "tree":
#   keep toFlatty(tree)

timeIt "tree":
  keep hashy(tree)
