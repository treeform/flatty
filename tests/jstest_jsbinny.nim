import flatty/jsbinny

# Does not work due to compiler bug:
# assert cast[int8](cast[uint8](int8(-12))) == -12
# assert cast[int16](cast[uint16](int16(-12))) == -12
assert cast[int32](cast[uint32](int32(-12))) == -12
assert cast[int64](cast[uint64](int64(-12))) == -12

assert toInt8(toUint8(int8(-12))) == -12
assert toInt16(toUint16(int16(-12))) == -12
#assert toInt32(toUint32(int32(-12))) == -12
#assert toInt64(toUint64(int64(-12))) == -12
