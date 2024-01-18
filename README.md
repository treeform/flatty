# Flatty - serializer and tools for flat binary blobs.

* `atlas use flatty`
* `nimble install flatty`

![Github Actions](https://github.com/treeform/flatty/workflows/Github%20Actions/badge.svg)

[API reference](https://treeform.github.io/flatty)

This library has no dependencies other than the Nim standard library.

## About

* Aim of `flatty` is to be the fastest and simplest serializer/deserializer for Nim.
* Also includes `hexprint` to print out binary data.
* Also includes `binny` a simpler replacement for StringStream (no IO effects, operates on a string)
* Also includes `hashy` a hash for any objects based on the flatty serializer.
* Also includes `encode` a way to convert to/from utf16 BE/LE and with BOM and utf32.

## Speed

Flatty aims to be fast. It achieves this by:
* Not using slowish StringStream.
* Checking if objects are "flat" and just copying them.
* Not doing anything extra like versioning, type checking, etc ...
* Liberal use of `{.inline.}`


### Serialize speed
```
name ............................... min time      avg time    std dv   runs
treeform/flatty .................... 6.303 ms      6.514 ms    ±0.181   x100
bingod/planetis-m ................. 11.337 ms     12.688 ms    ±1.641   x100
disruptek/frosty .................. 14.767 ms     14.924 ms    ±0.122   x100
treeform/jsony .................... 12.989 ms     13.343 ms    ±0.408   x100
```
### Deserialize speed
```
treeform/flatty ................... 10.526 ms     16.134 ms    ±5.508   x100
bingod/planetis-m binTo ........... 12.836 ms     17.993 ms    ±0.181   x100
disruptek/frosty .................. 38.513 ms     42.357 ms    ±0.535   x100
treeform/jsony .................... 96.830 ms    100.615 ms    ±0.992   x100
```

## JavaScript

Flatty supports Nim's `js` mode. Some features like `uint64`/`int64` are supported badly because of Nim's limitations. Serializing of non-Nim JavaScript objects is not supported.

## Versioning

Note, unlike `protobuf` or `thirft`, `flatty` has no versioning mechanism, if structure of your objects changes the resulting binary would be changed and could not be read back again. Because the schema is just plain Nim types, you need to make sure changing them does not impact your ability to read old flatty binary blobs.

## Compression

Flatty does not do compression it self but I recommend using the excellent https://github.com/guzba/supersnappy library to compress your flatty blobs before you send them over network or write them to disk. Snappy protocol is at this sweet spot of very fast compression, not the best but decent compression ratio, and very simple code.

## Networking

The `flatty` + `supersnappy` + `netty` were originally made to be used together. [Netty](https://github.com/treeform/netty) is a great for UDP networking for games.

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
