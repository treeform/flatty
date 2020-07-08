import fidget/opengl/perf, flatty/binny

const bufferLength = 100_000_000 * sizeof(uint64)

var
  s = ""
  total: int

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
    inc(total, s.readUint16(i * sizeof(uint16)).int)
  for i in 0 ..< s.len div sizeof(uint32):
    inc(total, s.readUint16(i * sizeof(uint32)).int)
  for i in 0 ..< s.len div sizeof(uint64):
    inc(total, s.readUint16(i * sizeof(uint64)).int)

echo total
