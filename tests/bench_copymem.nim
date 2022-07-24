import benchy, flatty

var seqence = newSeq[(uint8, uint8)](1_000_000)

echo seqence.len, " seq of (uint8, uint8)"

timeIt "treeform/flatty seq toFlatty":
  keep seqence.toFlatty()

var flattyBin = seqence.toFlatty()
timeIt "treeform/flatty seq fromFlatty":
  keep flattyBin.fromFlatty(seq[uint8])

var arr: array[1_000_000, (uint8, uint8)]

echo arr.len, " array of (uint8, uint8)"

timeIt "treeform/flatty arr toFlatty":
  keep arr.toFlatty()

var flattyBin2 = seqence.toFlatty()
timeIt "treeform/flatty arr fromFlatty":
  keep flattyBin2.fromFlatty(array[1_000_000, (uint8, uint8)])
