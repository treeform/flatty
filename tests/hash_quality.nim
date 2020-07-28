include flatty/hashy, sets

block:
  var hashSet: HashSet[Hash]
  for i in 0 ..< 1_000_000:
    var n = i
    let
      p = cast[ptr uint8](n.addr)
      h = ryan64nim(p, 8)
    hashSet.incl(h)

  echo "nim_fast"
  echo hashSet.len
  echo "---"

block:
  var hashSet: HashSet[Hash]
  for i in 0 ..< 1_000_000:
    var n = i
    let
      p = cast[ptr uint8](n.addr)
      h = sdbm(p, 8)
    hashSet.incl(h)

  echo "sdbm"
  echo hashSet.len
  echo "---"

block:
  var hashSet: HashSet[Hash]
  for i in 0 ..< 1_000_000:
    var n = i
    let
      p = cast[ptr uint8](n.addr)
      h = ryan64sdbm(p, 8)
    hashSet.incl(h)

  echo "sdbm_fast"
  echo hashSet.len
  echo "---"

block:
  var hashSet: HashSet[Hash]
  for i in 0 ..< 1_000_000:
    var n = i
    let
      p = cast[ptr uint8](n.addr)
      h = djb2(p, 8)
    hashSet.incl(h)

  echo "djb2"
  echo hashSet.len
  echo "---"

block:
  var hashSet: HashSet[Hash]
  for i in 0 ..< 1_000_000:
    var n = i
    let
      p = cast[ptr uint8](n.addr)
      h = ryan64djb2(p, 8)
    hashSet.incl(h)

  echo "djb2_fast"
  echo hashSet.len
  echo "---"
