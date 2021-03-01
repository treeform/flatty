## Takes bin-listing in ASCII format and turns them into real binary.
import parseutils, strutils

proc decodeBinListing*(text: string): string =

  for line in text.split("\n"):
    let line = line.strip()
    if line == "": continue
    let arr = line.split(":")
    var at: int
    discard parseHex(arr[0], at)
    let dataStr = arr[1].splitWhitespace()
    var data: seq[uint8]
    for d in dataStr:
      var dataByte: uint8
      discard parseHex(d, dataByte)
      data.add(dataByte)

    let max = at + data.len.int
    if result.len < max:
      result.setLen(max)
    for i, dataByte in data:
      result[at + i] = dataByte.char
