import flatty/hashy

echo hashy(1.int8)
echo hashy(1.uint8)
echo hashy(1.int16)
echo hashy(1.uint16)
echo hashy(1.int32)
echo hashy(1.uint32)
echo hashy(1.int64)
echo hashy(1.uint64)
echo hashy(1.float32)
echo hashy(1.float64)
echo hashy("the number one")
echo hashy("the number one, the number one")
echo hashy("the number one, the number one, the number one")

let
  a = "12345678a"
  b = "123456781"

doAssert ryan64nim(a[0].unsafeAddr, a.len) != ryan64nim(b[0].unsafeAddr, b.len)
doAssert ryan64sdbm(a[0].unsafeAddr, a.len) != ryan64sdbm(b[0].unsafeAddr, b.len)
doAssert ryan64djb2(a[0].unsafeAddr, a.len) != ryan64djb2(b[0].unsafeAddr, b.len)
doAssert hashy(a) != hashy(b)
