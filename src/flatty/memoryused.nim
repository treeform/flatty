proc memoryUsed*(o: ref object): int
proc memoryUsed*(o: object | tuple): int

proc memoryUsed*(o: object | tuple): int =
  for f in o.fields:
    when type(f) is object or type(f) is ref object or type(f) is tuple:
      result += f.memoryUsed()
    elif type(f) is seq or type(f) is array:
      if type(f) is seq:
        result += 16 # seq len + pointer values
      for item in f.items:
        when type(item) is object or type(item) is ref object:
          result += item.memoryUsed()
        else:
          result += sizeof(item)
    elif type(f) is string:
      result += 16 # len + pointer values
      result += f.len
    else:
      result += sizeof(f)

proc memoryUsed*(o: ref object): int =
  result += sizeof(o)
  if o == nil:
    return
  result += o[].memoryUsed()
