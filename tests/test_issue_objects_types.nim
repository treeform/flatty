type
  Issue41Kind* = enum
    issue41A, issue41B, issue41C

  Issue41Obj* = object
    case kind: Issue41Kind
    of issue41A:
      a: string
    else:
      b: string

  Issue34Bloom* = object
    capacity: uint64
    data: seq[uint64]

proc newIssue41Obj*(kind: Issue41Kind, value: string): Issue41Obj =
  case kind
  of issue41A:
    Issue41Obj(kind: kind, a: value)
  else:
    Issue41Obj(kind: kind, b: value)

proc kind*(x: Issue41Obj): Issue41Kind =
  x.kind

proc value*(x: Issue41Obj): string =
  case x.kind
  of issue41A:
    x.a
  else:
    x.b

proc initIssue34Bloom*(capacity: uint64, data: seq[uint64]): Issue34Bloom =
  Issue34Bloom(capacity: capacity, data: data)

proc capacity*(x: Issue34Bloom): uint64 =
  x.capacity

proc data*(x: Issue34Bloom): seq[uint64] =
  x.data
