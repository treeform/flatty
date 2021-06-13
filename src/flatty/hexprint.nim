import strutils

when defined(js):

  proc hexPrint*(buf: string): string =
    ## Prints a string in hex format of the old DOS debug program.
    ## Useful for looking at binary dumps.
    ## hexPrint("Hi how are you doing today?")
    ## 0000:  48 69 20 68 6F 77 20 61-72 65 20 79 6F 75 20 64 Hi how are you d
    ## 0010:  6F 69 6E 67 20 74 6F 64-61 79 3F .. .. .. .. .. oing today?.....
    var i = 0
    while i < buf.len:
      # Print the label.
      result.add(toHex(i, 4))
      result.add(": ")

      # Print the bytes.
      for j in 0 ..< 16:
        if i + j < buf.len:
          let b = buf[i + j]
          result.add(toHex(b.int, 2))
        else:
          result.add("..")
        if j == 7:
          result.add("-")
        else:
          result.add(" ")

      # Print the ascii.
      for j in 0 ..< 16:
        if i + j < buf.len:
          let b = buf[i + j]
          if ord(b) >= 32 and ord(b) <= 126:
            result.add(b.char)
          else:
            result.add('.')
        else:
          result.add(' ')

      i += 16
      result.add("\n")

else:

  proc hexPrint*(p: ptr uint8, len: int, startAddress = 0): string =
    ## Prints a string in hex format of the old DOS debug program.
    ## Useful for looking at binary dumps.
    ## hexPrint("Hi how are you doing today?")
    ## 0000:  48 69 20 68 6F 77 20 61-72 65 20 79 6F 75 20 64 Hi how are you d
    ## 0010:  6F 69 6E 67 20 74 6F 64-61 79 3F .. .. .. .. .. oing today?.....
    var i = 0
    while i < len:
      # Print the label.
      result.add(toHex(i + startAddress, 16))
      result.add(": ")

      # Print the bytes.
      for j in 0 ..< 16:
        if i + j < len:
          let b = cast[ptr uint8](cast[int](p) + i + j)[]
          result.add(toHex(b.int, 2))
        else:
          result.add("..")
        if j == 7:
          result.add("-")
        else:
          result.add(" ")

      # Print the ascii.
      for j in 0 ..< 16:
        if i + j < len:
          let b = cast[ptr uint8](cast[int](p) + i + j)[]
          if ord(b) >= 32 and ord(b) <= 126:
            result.add(b.char)
          else:
            result.add('.')
        else:
          result.add(' ')

      i += 16
      result.add("\n")

  proc hexPrint*(buf: string, startAddress = 0): string =
    ## Prints a string in hex format of the old DOS debug program.
    ## Useful for looking at binary dumps.
    ## hexPrint("Hi how are you doing today?")
    ## 0000:  48 69 20 68 6F 77 20 61-72 65 20 79 6F 75 20 64 Hi how are you d
    ## 0010:  6F 69 6E 67 20 74 6F 64-61 79 3F .. .. .. .. .. oing today?.....
    hexPrint(cast[ptr uint8](buf[0].unsafeAddr), buf.len, startAddress)
