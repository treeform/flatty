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
* Only Nim-owned values are serialized. Raw pointers, cstrings, procs, and distinct OS handles are rejected.

## Speed

Flatty aims to be fast. It achieves this by:
* Not using slowish StringStream.
* Checking if objects are "flat" and just copying them.
* Not doing anything extra like versioning, type checking, etc ...
* Liberal use of `{.inline.}`

Benchmark below serializes and deserializes a 11125 node tree.

### Serialize speed
```
name ............................... min time      avg time    std dv   runs
treeform/flatty .................... 2.265 ms      2.413 ms    +/-0.114   x100
bingo/planetis-m ................... 2.632 ms      2.705 ms    +/-0.056   x100
disruptek/frosty ................... 6.280 ms      6.532 ms    +/-0.142   x100
std/marshal ....................... 85.178 ms     93.228 ms    +/-9.956   x100
treeform/jsony ..................... 9.618 ms     10.835 ms    +/-1.276   x100
```
### Deserialize speed
```
treeform/flatty .................... 2.643 ms      4.285 ms    +/-0.597   x100
bingo/planetis-m binTo ............. 5.735 ms      5.969 ms    +/-0.132   x100
disruptek/frosty ................... 9.529 ms      9.959 ms    +/-0.290   x100
std/marshal ...................... 148.723 ms    155.663 ms    +/-4.763   x100
treeform/jsony .................... 12.023 ms     13.514 ms    +/-1.143   x100
```

## JavaScript

Flatty supports Nim's `js` mode. Some features like `uint64`/`int64` are supported badly because of Nim's limitations. Serializing of non-Nim JavaScript objects is not supported.

## Integer Width Modes

By default, Flatty serializes Nim's default `int`, `uint`, and container lengths using the target's native `int` width. A 32-bit target uses 32-bit values, and a 64-bit target uses 64-bit values.

You can force a specific width with `-d:flatty32` or `-d:flatty64`. Use the same mode when reading and writing a blob. Fixed-width types like `int32`, `uint32`, `int64`, and `uint64` are not affected by these modes.

## Versioning

Note, unlike `protobuf` or `thirft`, `flatty` has no versioning mechanism, if structure of your objects changes the resulting binary would be changed and could not be read back again. Because the schema is just plain Nim types, you need to make sure changing them does not impact your ability to read old flatty binary blobs.

## Compression

Flatty does not do compression it self but I recommend using the excellent https://github.com/guzba/supersnappy library to compress your flatty blobs before you send them over network or write them to disk. Snappy protocol is at this sweet spot of very fast compression, not the best but decent compression ratio, and very simple code.

## Networking

The `flatty` + `supersnappy` + `netty` were originally made to be used together. [Netty](https://github.com/treeform/netty) is a great for UDP networking for games.

## Untrusted input and hardening

Flatty is often used to decode data that arrives over the network, so `fromFlatty` is built to never crash the process on a malformed or hostile blob. A bad blob fails with a **catchable** error instead of a segfault, an out-of-memory abort, or a stack overflow:

* Every read is bounds-checked against the buffer, so truncated blobs can't over-read (this stays on even under `-d:danger`).
* Length and element-count prefixes are validated against the bytes remaining before anything is allocated, so a bogus length can't drive a huge allocation.
* Enum discriminators are range-checked before an object variant is built, so an out-of-range tag can't corrupt a variant or segfault.
* `Table`/`HashSet` preallocation from an untrusted count is capped, so a small blob can't force a huge hash-table allocation.
* A stack-pointer watermark stops deeply nested input (a long `ref`/`seq` chain) before it overflows the thread stack.

Decode failures raise `FlattyError` (bad length, count, or enum) or `IndexDefect` (truncation). Wrap the decode and handle both:

```nim
try:
  let msg = data.fromFlatty(Message)
  ...
except CatchableError, Defect:
  discard # drop the blob / disconnect the peer
```
