import flatty/objvar, json

# Test Object variants
type
  Node = ref object
    val: string
  NodeNumKind = enum  # the different node types
    nkInt,          # a leaf with an integer value
    nkFloat,        # a leaf with a float value
  NodeNum = ref object
    case kind: NodeNumKind  # the ``kind`` field is the discriminator
    of nkInt: intVal: int
    of nkFloat: floatVal: float

var node = Node()
var nodeNum = NodeNum(kind: nkInt, intVal: 0)
doAssert nodeNum.isObjectVariant == true
doAssert node.isObjectVariant == false
doAssert "".isObjectVariant == false
doAssert (2).isObjectVariant == false

doAssert nodeNum.discriminatorFieldName == "kind"
doAssert nodeNum.discriminatorField == nkInt

var nodeNum2: NodeNum
new(nodeNum2, nkFloat)
doAssert nodeNum2.kind == nkFloat
doAssert nodeNum2.discriminatorField == nkFloat
doAssert nodeNum2.discriminatorField == nodeNum2.kind

var jsonNode = parseJson("{\"json\": true, \"count\":20}")
doAssert jsonNode.isObjectVariant == true
doAssert jsonNode.discriminatorFieldName == "kind"
doAssert jsonNode.discriminatorField == JObject
new(jsonNode, JArray)
doAssert jsonNode.discriminatorField == JArray
