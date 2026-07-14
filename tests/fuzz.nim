## Fuzz tests for the flatty decode path (`fromFlatty`).
##
## Goal: decoding untrusted / corrupt bytes must never take the process down.
## An acceptable outcome for a bad input is a *catchable* error
## (CatchableError or Defect). An UNacceptable outcome is a hard abort the
## caller cannot recover from: an out-of-memory `quit` (typically from a
## bogus length prefix driving a huge allocation) or a SIGSEGV (typically
## from building an object variant with an out-of-range discriminator).
##
## Because those bad outcomes kill the process, we can't just loop in-process:
## the first hard abort would end the run with no idea which input caused it.
## So this harness runs the actual decoding in a child process that writes the
## current input to a checkpoint file before each attempt. When the child
## aborts, the parent reads the checkpoint to recover the exact reproducer,
## records it, and resumes the child just past that input. Everything is
## driven by a seeded PRNG, so every reproducer replays deterministically.
##
## Run from the repo root:  nim r tests/fuzz.nim
## Replay one input by hand:  nim r tests/fuzz.nim --replay <type> <hex>
## (the hex for each finding is printed next to its CRASH line)

import
  std/[os, osproc, random, strutils, tables],
  flatty, flatty/binny

# Types under fuzz. These mirror the shapes real protocols build on flatty:
# scalars, length-prefixed strings/seqs, tables, an object variant (the
# ClientPacket shape), and a recursive ref graph.

type
  FuzzKind = enum fkA, fkB, fkC, fkD
  FuzzVariant = ref object
    case kind: FuzzKind
    of fkA:
      n: int
      s: string
    of fkB:
      xs: seq[int]
    of fkC:
      discard
    of fkD:
      t: Table[string, int]

  # Holey enum: defined ordinals 0, 2, 5. Values 1, 3, 4 sit in holes --
  # low..high range checks accept them, then `new(x, disc)` segfaults.
  HoleyKind = enum hkA = 0, hkB = 2, hkC = 5
  HoleyVariant = ref object
    case kind: HoleyKind
    of hkA:
      n: int
    of hkB:
      s: string
    of hkC:
      xs: seq[int]

  Nested = ref object
    id: int
    name: string
    kids: seq[Nested]

# The set of types we fuzz, addressed by name on the command line.
const FuzzTypes = [
  "int", "string", "seqint", "seqstr", "table", "variant", "holey", "nested"
]

# Encoding helpers for hand-built adversarial inputs.

proc i64(v: int64): string = result.addInt64(v)

proc toHex(s: string): string =
  for c in s: result.add toHex(c.ord, 2)

proc fromHex(h: string): string =
  var i = 0
  while i + 1 < h.len:
    result.add chr(parseHexInt(h[i .. i+1]))
    i += 2

# Deterministic "corner" inputs per type: the specific byte patterns most
# likely to trip an unchecked decoder. These run first, before random fuzz.
proc corners(typ: string): seq[string] =
  case typ
  of "int":
    @["", "\x00", i64(1)[0 ..< 3]]                 # empty / short reads
  of "string", "seqstr", "seqint", "table":
    @[
      "",
      i64(-1),                                     # negative length prefix
      i64(-100),
      i64(0x7fffffffffffffff),                     # enormous length prefix
      i64(0x0fffffffffffffff),
      i64(1_000_000_000),                          # 1e9 elements/bytes
      i64(5) & "ab",                               # length says 5, 2 present
    ]
  of "variant":
    @[
      "",
      i64(-1),                                     # negative discriminator
      i64(9999),                                   # out-of-range discriminator
      i64(int(high(FuzzKind)) + 1),                # just past the enum
      i64(int(fkA)),                               # valid tag, missing fields
    ]
  of "holey":
    # HoleyVariant is a ref, so byte 0 is the nil flag (0 = present). Without
    # that leading 0 the decoder returns nil and never touches the disc.
    @[
      "",
      "\x00",                                      # non-nil, missing disc
      "\x00" & i64(-1),                            # negative discriminator
      "\x00" & i64(9999),                          # past high(HoleyKind)
      "\x00" & i64(1),                             # hole between hkA and hkB
      "\x00" & i64(3),                             # hole between hkB and hkC
      "\x00" & i64(4),                             # hole between hkB and hkC
      "\x00" & i64(int(hkA)),                      # valid tag, missing fields
      "\x00" & i64(int(hkB)),
      "\x00" & i64(int(hkC)),
    ]
  of "nested":
    @[
      "",
      "\x00",                                      # isNil byte only
      "\x01" & i64(5),                             # non-nil, then truncated
      "\x01" & i64(0) & i64(0) & i64(-1),          # bad kids length
    ]
  else:
    @[]

# Random input generation. A mix of pure-random bytes and mutations of a
# valid encoding (truncate / bitflip / extend) -- mutations reach deeper into
# the decoder than pure noise, which usually dies on the first length read.

proc randBytes(r: var Rand, n: int): string =
  for _ in 0 ..< n: result.add chr(r.rand(255))

proc genValid(r: var Rand, typ: string): string =
  ## A well-formed encoding of a random value of `typ`.
  case typ
  of "int":
    r.rand(int.high).toFlatty
  of "string":
    r.randBytes(r.rand(20)).toFlatty
  of "seqint":
    var xs: seq[int]
    for _ in 0 ..< r.rand(8): xs.add r.rand(1000)
    xs.toFlatty
  of "seqstr":
    var xs: seq[string]
    for _ in 0 ..< r.rand(6): xs.add r.randBytes(r.rand(8))
    xs.toFlatty
  of "table":
    var t: Table[string, int]
    for _ in 0 ..< r.rand(6): t[r.randBytes(1 + r.rand(5))] = r.rand(1000)
    t.toFlatty
  of "variant":
    let k = FuzzKind(r.rand(int(high(FuzzKind))))
    var v: FuzzVariant
    case k
    of fkA: v = FuzzVariant(kind: fkA, n: r.rand(1000), s: r.randBytes(r.rand(8)))
    of fkB:
      var xs: seq[int]
      for _ in 0 ..< r.rand(6): xs.add r.rand(1000)
      v = FuzzVariant(kind: fkB, xs: xs)
    of fkC: v = FuzzVariant(kind: fkC)
    of fkD:
      var t: Table[string, int]
      for _ in 0 ..< r.rand(4): t[r.randBytes(1 + r.rand(4))] = r.rand(100)
      v = FuzzVariant(kind: fkD, t: t)
    v.toFlatty
  of "holey":
    # Pick only defined ordinals so genValid stays well-formed.
    let defined = [hkA, hkB, hkC]
    let k = defined[r.rand(defined.len - 1)]
    var v: HoleyVariant
    case k
    of hkA: v = HoleyVariant(kind: hkA, n: r.rand(1000))
    of hkB: v = HoleyVariant(kind: hkB, s: r.randBytes(r.rand(8)))
    of hkC:
      var xs: seq[int]
      for _ in 0 ..< r.rand(6): xs.add r.rand(1000)
      v = HoleyVariant(kind: hkC, xs: xs)
    v.toFlatty
  of "nested":
    proc gen(r: var Rand, depth: int): Nested =
      result = Nested(id: r.rand(1000), name: r.randBytes(r.rand(6)))
      if depth > 0:
        for _ in 0 ..< r.rand(3): result.kids.add gen(r, depth - 1)
    gen(r, 2).toFlatty
  else:
    ""

proc mutate(r: var Rand, valid: string): string =
  ## Corrupt a valid encoding in a random way.
  case r.rand(3)
  of 0:                                            # truncate
    result = if valid.len == 0: "" else: valid[0 ..< r.rand(valid.len)]
  of 1:                                            # bit-flips
    result = valid
    if result.len > 0:
      for _ in 0 ..< (1 + r.rand(3)):
        let idx = r.rand(result.len - 1)
        result[idx] = chr(result[idx].ord xor (1 shl r.rand(7)))
  else:                                            # extend with noise
    result = valid & r.randBytes(1 + r.rand(16))

proc genInput(r: var Rand, typ: string, idx, cornerCount: int): string =
  ## Deterministic input for iteration `idx`. Always advances `r` for the
  ## random range so that resume-after-crash stays aligned.
  if idx < cornerCount:
    corners(typ)[idx]                              # no RNG draw
  elif r.rand(3) == 0:
    r.randBytes(r.rand(40))                        # pure noise
  else:
    r.mutate(genValid(r, typ))                     # mutated valid

# The decode step. No try/except around the actual crash-prone call inside
# the child's "attempt" -- we want the real OS-level outcome. Catchable errors
# are caught and counted; hard aborts kill the child and are caught by the
# parent via the exit code.

proc decodeAs(typ, data: string) =
  ## Decode `data` as `typ`. Mirrors `fromFlatty` exactly; may raise (caught
  ## by caller) or hard-abort (kills the process).
  case typ
  of "int":     discard data.fromFlatty(int)
  of "string":  discard data.fromFlatty(string)
  of "seqint":  discard data.fromFlatty(seq[int])
  of "seqstr":  discard data.fromFlatty(seq[string])
  of "table":   discard data.fromFlatty(Table[string, int])
  of "variant":
    let v = data.fromFlatty(FuzzVariant)
    if v != nil: discard ord(v.kind)              # touch the discriminator
  of "holey":
    let v = data.fromFlatty(HoleyVariant)
    if v != nil:
      # A hole ordinal that survives fromFlatty is a hardening failure: under
      # -d:danger, `case v.kind` silently takes the wrong branch; under
      # -d:release, field access can SIGSEGV. low..high range checks miss
      # holes, so treat an undefined kind as a hard abort for the harness.
      if v.kind != hkA and v.kind != hkB and v.kind != hkC:
        quit(139)
  of "nested":
    let n = data.fromFlatty(Nested)
    if n != nil: discard n.kids.len
  else: discard

# Child mode: fuzz one type, checkpointing each input before the attempt.

proc runChild(typ: string, seed: int64, total, skipTo: int, ckpt: string) =
  var r = initRand(seed)
  let cornerCount = corners(typ).len
  var caught, clean = 0
  for idx in 0 ..< total:
    let input = genInput(r, typ, idx, cornerCount)
    if idx < skipTo:
      continue                                     # already covered; keep RNG aligned
    # Checkpoint BEFORE the risky decode so a hard abort leaves a reproducer.
    writeFile(ckpt, $idx & "\n" & input.toHex)
    try:
      decodeAs(typ, input)
      inc clean
    except CatchableError, Defect:
      inc caught
  writeFile(ckpt & ".summary",
    "caught=" & $caught & " clean=" & $clean & " total=" & $total)
  quit(0)

# Parent mode: drive children, recover reproducers across hard aborts.

type
  Crash = object
    typ: string
    idx: int
    hex: string
    code: int
    reason: string

const ChildTimeoutMs = 1500                        # a decode taking this long
                                                   # is thrashing on a bogus
                                                   # length -> treat as abort

proc runChildProc(exe, typ: string, seed: int64, total, skipTo: int,
                  ckpt: string): tuple[code: int, timedOut: bool] =
  ## Start one child and enforce a wall-clock timeout, killing a hung child.
  let p = startProcess(exe, args = @[
    "--child", typ, $seed, $total, $skipTo, ckpt],
    options = {poUsePath, poStdErrToStdOut})
  defer: p.close()
  var waited = 0
  while p.running and waited < ChildTimeoutMs:
    sleep(20)
    waited += 20
  if p.running:
    p.terminate(); sleep(50)
    if p.running: p.kill()
    discard p.waitForExit()
    return (137, true)
  return (p.waitForExit(), false)

proc fuzzType(exe, typ: string, seed: int64, total: int,
              crashes: var seq[Crash]) =
  let ckpt = getTempDir() / ("flatty_fuzz_" & typ & ".ckpt")
  removeFile(ckpt & ".summary")
  var skipTo = 0
  while true:
    let (code, timedOut) = runChildProc(exe, typ, seed, total, skipTo, ckpt)
    if code == 0 and not timedOut:
      if fileExists(ckpt & ".summary"):
        echo "  SUMMARY ", typ, " ", readFile(ckpt & ".summary")
      break
    # Hard abort (crash or thrash-timeout): recover the reproducer.
    var idx = skipTo
    var hex = ""
    if fileExists(ckpt):
      let parts = readFile(ckpt).splitLines
      if parts.len >= 2:
        idx = parseInt(parts[0])
        hex = parts[1]
    let reason =
      if timedOut: "timeout/oom-thrash"
      elif code == 139: "SIGSEGV"
      else: "abort/quit"
    crashes.add Crash(typ: typ, idx: idx, hex: hex, code: code, reason: reason)
    echo "  CRASH ", typ, " @", idx, " (", reason, " exit=", code,
      ") input=", (if hex.len <= 48: hex else: hex[0 ..< 48] & "..")
    if idx + 1 >= total: break
    skipTo = idx + 1                               # resume just past the crash

when isMainModule:
  # Child dispatch.
  if paramCount() >= 1 and paramStr(1) == "--child":
    runChild(paramStr(2), parseInt(paramStr(3)).int64,
      parseInt(paramStr(4)), parseInt(paramStr(5)), paramStr(6))

  # Replay a single reproducer:  test_fuzz --replay <type> <hex>
  # Decodes with no error handling so you can watch the abort under a debugger.
  if paramCount() >= 2 and paramStr(1) == "--replay":
    decodeAs(paramStr(2), fromHex(paramStr(3)))
    echo "decoded without aborting"
    quit(0)

  # --- Correctness precondition: valid values must round-trip. ---
  block:
    var r = initRand(1)
    for typ in FuzzTypes:
      for _ in 0 ..< 50:
        let v = genValid(r, typ)
        try:
          decodeAs(typ, v)
        except CatchableError, Defect:
          doAssert false, "valid " & typ & " failed to round-trip: " & v.toHex
    echo "round-trip of valid values: ok"

  # --- Fuzz. ---
  let exe = getAppFilename()
  const total = 200
  var crashes: seq[Crash]
  echo "=== fuzzing ", FuzzTypes.len, " types x ", total, " inputs each ==="
  for i, typ in FuzzTypes:
    fuzzType(exe, typ, 0xF1A77'i64 + i.int64, total, crashes)

  # --- Report. ---
  echo ""
  echo "=== fuzz summary ==="
  if crashes.len == 0:
    echo "no hard aborts: fromFlatty survived every input (catchable errors ok)"
  else:
    var byType: Table[string, int]
    for c in crashes: byType.mgetOrPut(c.typ, 0).inc
    echo crashes.len, " hard aborts (uncatchable process kills):"
    for typ, n in byType:
      echo "  ", typ, ": ", n
    echo ""
    echo "reproducers (decode the hex as the named type to replay):"
    for c in crashes:
      echo "  ", c.typ, " (", c.reason, ") hex=", c.hex

  # This assertion FAILS until flatty's decode path is hardened. Every crash
  # above is a byte string that a remote peer could send to kill the process.
  doAssert crashes.len == 0,
    $crashes.len & " inputs hard-abort fromFlatty (see reproducers above); " &
    "decode must fail with a catchable error, never quit/segfault"
