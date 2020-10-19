import fidget/opengl/perf, flatty/binny

const bufferLength = 100_000_000 * sizeof(uint64)

var
  s = ""
  total: uint64

timeIt "binny":
  for i in 0 ..< bufferLength div sizeof(uint16):
    s.addUint16((i mod 10).uint16)
  s.setLen(0)
  for i in 0 ..< bufferLength div sizeof(uint32):
    s.addUint32((i mod 10).uint32)
  s.setLen(0)
  for i in 0 ..< bufferLength div sizeof(uint64):
    s.addUint64((i mod 10).uint64)

  for i in 0 ..< s.len div sizeof(uint16):
    s.writeUint64(i, (i mod 10).uint16)
  for i in 0 ..< s.len div sizeof(uint32):
    s.writeUint64(i, (i mod 10).uint32)
  for i in 0 ..< s.len div sizeof(uint64):
    s.writeUint64(i, (i mod 10).uint64)

  for i in 0 ..< s.len div sizeof(uint16):
    total += s.readUint16(i * sizeof(uint16))
  for i in 0 ..< s.len div sizeof(uint32):
    total += s.readUint32(i * sizeof(uint32))
  for i in 0 ..< s.len div sizeof(uint64):
    total += swap(s.readUint64(i * sizeof(uint64)))

echo total
