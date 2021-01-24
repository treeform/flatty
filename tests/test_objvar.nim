import flatty/objvar, json

# Test Object variants
type
  Node = ref object
    val: string
  NodeKind = enum # the different node types
    nkInt,        # a leaf with an integer value
    nkFloat,      # a leaf with a float value
  RefNode = ref object
    active: bool
    case kind: NodeKind # the ``kind`` field is the discriminator
    of nkInt: intVal: int
    of nkFloat: floatVal: float
  ValueNode = ref object
    active: bool
    case kind: NodeKind # the ``kind`` field is the discriminator
    of nkInt: intVal: int
    of nkFloat: floatVal: float

block:
  var node = Node()
  var nodeNum = RefNode(kind: nkInt, intVal: 0)
  doAssert nodeNum.isObjectVariant == true
  doAssert node.isObjectVariant == false
  doAssert "".isObjectVariant == false
  doAssert (2).isObjectVariant == false

  doAssert nodeNum.discriminatorFieldName == "kind"
  doAssert nodeNum.discriminatorField == nkInt

  var nodeNum2: RefNode
  new(nodeNum2, nkFloat)
  doAssert nodeNum2.kind == nkFloat
  doAssert nodeNum2.discriminatorField == nkFloat
  doAssert nodeNum2.discriminatorField == nodeNum2.kind

block:
  var jsonNode = parseJson("{\"json\": true, \"count\":20}")
  doAssert jsonNode.isObjectVariant == true
  doAssert jsonNode.discriminatorFieldName == "kind"
  doAssert jsonNode.discriminatorField == JObject
  new(jsonNode, JArray)
  doAssert jsonNode.discriminatorField == JArray

block:
  var node = ValueNode(kind: nkInt, intVal: 0)
  doAssert node.isObjectVariant == true
  doAssert node.discriminatorFieldName == "kind"
  doAssert node.discriminatorField == nkInt
