# Flatty - serializer and tools for flat binary files.

* Aim of flatty is to be the best serializer/deserializer for nim.
* Also includes hexprint to print out binary data.
* Also includes binny a simpler replacement for StringStream (no IO effects, operates on a string)
* Also includes hashy a hash for any objects based on the serializer.

# API: flatty

```nim
import flatty
```

## **func** toFlatty

Takes structures and turns them into binary string.

```nim
func toFlatty[T](x: T): string
```

## **func** fromFlatty

Takes binary string and turn into structures.

```nim
func fromFlatty[T](s: string; x: typedesc[T]): T
```

# API: flatty/hexprint

```nim
import flatty/hexprint
```

## **proc** hexPrint

Prints a string in hex format of the old DOS debug program. Useful for looking at binary dumps.
```nim
hexPrint("Hi how are you doing today?")
```
```
0000:  48 69 20 68 6F 77 20 61-72 65 20 79 6F 75 20 64 Hi how are you d
0010:  6F 69 6E 67 20 74 6F 64-61 79 3F .. .. .. .. .. oing today?.....
```

```nim
proc hexPrint(buf: string): string
```

# API: flatty/binny

```nim
import flatty/binny
```

## **func** readUint8


```nim
func readUint8(s: string; i: int): uint8
```

## **func** writeUint8


```nim
func writeUint8(s: var string; i: int; v: uint8)
```

## **func** addUint8


```nim
func addUint8(s: var string; v: uint8)
```

## **func** readUint16


```nim
func readUint16(s: string; i: int): uint16
```

## **func** writeUint16


```nim
func writeUint16(s: var string; i: int; v: uint16)
```

## **func** addUint16


```nim
func addUint16(s: var string; v: uint16)
```

## **func** readUint32


```nim
func readUint32(s: string; i: int): uint32
```

## **func** writeUint32


```nim
func writeUint32(s: var string; i: int; v: uint32)
```

## **func** addUint32


```nim
func addUint32(s: var string; v: uint32)
```

## **func** readUint64


```nim
func readUint64(s: string; i: int): uint64
```

## **func** writeUint64


```nim
func writeUint64(s: var string; i: int; v: uint64)
```

## **func** addUint64


```nim
func addUint64(s: var string; v: uint64)
```

## **func** readInt8


```nim
func readInt8(s: string; i: int): int8
```

## **func** writeInt8


```nim
func writeInt8(s: var string; i: int; v: int8)
```

## **func** addInt8


```nim
func addInt8(s: var string; v: int8)
```

## **func** readInt16


```nim
func readInt16(s: string; i: int): int16
```

## **func** writeInt16


```nim
func writeInt16(s: var string; i: int; v: int16)
```

## **func** addInt16


```nim
func addInt16(s: var string; i: int16)
```

## **func** readInt32


```nim
func readInt32(s: string; i: int): int32
```

## **func** writeInt32


```nim
func writeInt32(s: var string; i: int; v: int32)
```

## **func** addInt32


```nim
func addInt32(s: var string; i: int32)
```

## **func** readInt64


```nim
func readInt64(s: string; i: int): int64
```

## **func** writeInt64


```nim
func writeInt64(s: var string; i: int; v: int64)
```

## **func** addInt64


```nim
func addInt64(s: var string; i: int64)
```

## **func** readFloat32


```nim
func readFloat32(s: string; i: int): float32
```

## **func** addFloat32


```nim
func addFloat32(s: var string; v: float32)
```

## **func** readFloat64


```nim
func readFloat64(s: string; i: int): float64
```

## **func** addFloat64


```nim
func addFloat64(s: var string; v: float64)
```

## **func** addStr


```nim
func addStr(s: var string; v: string)
```

## **func** readStr


```nim
func readStr(s: string; i: int; v: int): string
```

## **func** swap


```nim
func swap(v: uint8): uint8
```

## **func** swap


```nim
func swap(v: uint16): uint16
```

## **func** swap


```nim
func swap(v: uint32): uint32
```

## **func** swap


```nim
func swap(v: uint64): uint64
```

## **func** maybeSwap


```nim
func maybeSwap[T](v: T; enable: bool): T
```
