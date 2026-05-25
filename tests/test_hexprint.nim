when defined(js):
  import flatty/jsbinny
else:
  import flatty/binny, streams

import flatty/hexprint

var output = ""

proc writeLine(line: string) =
  output.add(line)
  output.add("\n")

block:
  writeLine "Sentence:"
  writeLine hexPrint("Hi how are you doing today?")

block:
  writeLine "ASCII:"
  var bin = ""
  for i in 0 .. 255:
    bin.add chr(i)
  writeLine hexPrint(bin)

block:
  writeLine "int16s:"
  var bin = ""
  for i in 0 .. 16:
    bin.addUint16(i.uint16)
  writeLine hexPrint(bin)

block:
  writeLine "int32s"
  var bin = ""
  for i in 0 .. 16:
    bin.addUint32(1000 * i.uint32)
  writeLine hexPrint(bin)

when not defined(js):
  var s = newFileStream("tests/test_hexprint-output.txt", fmWrite)
  s.write(output)
  s.close()
