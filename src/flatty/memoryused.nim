proc memoryUsed*(o: ref object): int
proc memoryUsed*(o: object | tuple): int

proc memoryUsed*(o: object | tuple): int =
  for field in o.fields:
    when type(field) is object | ref object | tuple:
      result += field.memoryUsed()
    elif type(field) is seq or type(field) is array:
      if type(field) is seq:
        result += 16 # seq len + pointer values
      for item in field.items:
        when type(item) is object | ref object | tuple:
          result += item.memoryUsed()
        else:
          result += sizeof(item)
    elif type(field) is string:
      result += 16 # len + pointer values
      result += field.len
    else:
      result += sizeof(field)

proc memoryUsed*(o: ref object): int =
  result += sizeof(o)
  if o == nil:
    return
  result += o[].memoryUsed()
