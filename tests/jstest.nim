echo cast[uint8](int8(-12)), " vs ", 244
echo cast[uint16](int16(-12)), " vs ", 65524
echo cast[uint32](int32(-12)), " vs ", 4294967284
#echo cast[uint64](int64(-12)), " vs ", 18446744073709551604u64

echo cast[int8](cast[uint8](int8(-12))), " vs ", -12
echo cast[int16](cast[uint16](int16(-12))), " vs ", -12
echo cast[int32](cast[uint32](int32(-12))), " vs ", -12
#echo cast[int64](cast[uint64](int64(-12))), " vs ", -12
