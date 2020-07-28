include flatty/hashy

const bucketCount = 32

var buckets = newSeq[int](bucketCount)

for i in 0 ..< 1_000_000:
  var n = i
  let
    p = cast[ptr uint8](n.addr)
    h = ryan64nim(p, 8).uint64
    b = (h mod buckets.len.uint64).int
  buckets[b] = buckets[b] + 1

echo "nim_fast"
echo $buckets
echo "---"

buckets = newSeq[int](bucketCount)

for i in 0 ..< 1_000_000:
  var n = i
  let
    p = cast[ptr uint8](n.addr)
    h = sdbm(p, 8).uint64
    b = (h mod buckets.len.uint64).int
  buckets[b] = buckets[b] + 1

echo "sdbm"
echo $buckets
echo "---"

buckets = newSeq[int](bucketCount)

for i in 0 ..< 1_000_000:
  var n = i
  let
    p = cast[ptr uint8](n.addr)
    h = djb2(p, 8).uint64
    b = (h mod buckets.len.uint64).int
  buckets[b] = buckets[b] + 1

echo "djb2"
echo $buckets
echo "---"

buckets = newSeq[int](bucketCount)

for i in 0 ..< 1_000_000:
  var n = i
  let
    p = cast[ptr uint8](n.addr)
    h = ryan64sdbm(p, 8).uint64
    b = (h mod buckets.len.uint64).int
  buckets[b] = buckets[b] + 1

echo "sdbm_fast"
echo $buckets
echo "---"

buckets = newSeq[int](bucketCount)

for i in 0 ..< 1_000_000:
  var n = i
  let
    p = cast[ptr uint8](n.addr)
    h = ryan64djb2(p, 8).uint64
    b = (h mod buckets.len.uint64).int
  buckets[b] = buckets[b] + 1

echo "djb2_fast"
echo $buckets
echo "---"
