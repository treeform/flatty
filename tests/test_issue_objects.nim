import
  flatty,
  test_issue_objects_types

# #41: imported object variants can keep their discriminator private.
block:
  let original = newIssue41Obj(issue41B, "hidden variant payload")
  let roundTrip = original.toFlatty.fromFlatty(Issue41Obj)
  doAssert roundTrip.kind == issue41B
  doAssert roundTrip.value == original.value

# #34: imported objects can have private fields with public getter procs.
block:
  let original = initIssue34Bloom(1024'u64, @[1'u64, 8, 27, 64])
  let roundTrip = original.toFlatty.fromFlatty(Issue34Bloom)
  doAssert roundTrip.capacity == original.capacity
  doAssert roundTrip.data == original.data

# #32: arrays with non-zero index ranges use their real lower bound.
block:
  var arr: array[-2..0, int]
  var arr2: array[10..11, int]

  for i in arr.low .. arr.high:
    arr[i] = i

  for i in arr2.low .. arr2.high:
    arr2[i] = i

  let arrRoundTrip = arr.toFlatty.fromFlatty(array[-2..0, int])
  let arr2RoundTrip = arr2.toFlatty.fromFlatty(array[10..11, int])

  for i in arr.low .. arr.high:
    doAssert arrRoundTrip[i] == arr[i]

  for i in arr2.low .. arr2.high:
    doAssert arr2RoundTrip[i] == arr2[i]

# #29: range fields reject out-of-range serialized values.
block:
  type RangeObj = object
    a: 0..3

  let original = RangeObj(a: 3)
  doAssert original.toFlatty.fromFlatty(RangeObj) == original

  let invalid = 10.toFlatty
  doAssertRaises(RangeDefect):
    discard invalid.fromFlatty(RangeObj)
