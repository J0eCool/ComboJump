import
  algorithm,
  macros,
  parseutils,
  sequtils,
  strutils,
  tables

import
  entity,
  util

type
  JSONKind = enum
    jsObject
    jsArray
    jsString
    jsNull
    jsError
  JSON = object
    case kind*: JSONKind
    of jsObject:
      obj: Table[string, JSON]
    of jsArray:
      arr: seq[JSON]
    of jsString:
      str: string
    of jsNull:
      discard
    of jsError:
      msg: string

proc parseStringToJSON(str: string): JSON {.procvar.} =
  let
    last = len(str) - 1
    inner = str[1..last-1]
  case str[0]
  of '"':
    if str[last] == '"':
      JSON(kind: jsString, str: inner)
    else:
      JSON(kind: jsError, msg: "unmatched \" on string: " & str)
  of '[':
    if str[last] == ']':
      let parts = inner.split(",").map(parseStringToJSON)
      JSON(kind: jsArray, arr: parts)
    else:
      JSON(kind: jsError, msg: "unmatched [ on string: " & str)

  else:
    JSON(kind: jsError, msg: "unknown format: " & str)

proc serializeJSON(json: JSON): string =
  case json.kind
  of jsString:
    result = "\"" & json.str & "\""
  of jsObject:
    result = "{object}"
  of jsArray:
    result = "["
    var first = true
    for x in json.arr:
      if not first:
        result &= ","
      first = false
      result &= serializeJSON(x)
    result &= "]"
  of jsNull:
    result = "null"
  of jsError:
    result = json.msg

echo "Serialized: ", serializeJSON(parseStringToJSON(
  """["lol","butts"]"""
  # """"lol""""
))

proc readJSONFile(filename: string): JSON =
  parseStringToJSON(readFile(filename).string)

type Data = Table[string, int]
const sysFile = "systems.json"
proc readData(): Data =
  result = initTable[string, int](64)
  let
    inStr = readFile(sysFile).string
    lines = inStr.split("\n")
  for ln in lines:
    let parts = ln.split(":")
    if parts.len > 1:
      let
        name = parts[0]
        count = parts[1].parseInt
      result[name] = count

proc writeData(data: Data) =
  var outStr = ""
  for k, v in data.pairs:
    outStr &= k & ":" & $v & "\n"
  writeFile(sysFile, outStr)

proc getNextId(data: Data): int =
  var ids: seq[int] = @[]
  for d in data.values:
    ids.add d
  ids.sort(cmp)
  for x in ids:
    if x > result:
      return
    result += 1

macro defineSystem*(body: untyped): untyped =
  var data = readData()
  let key = $body[0].name
  if not data.hasKey(key):
    let nextId = getNextId(data)
    data[key] = nextId

  var ps = body[0].params
  ps[0] = ident("Events")
  ps.insert 1, newIdentDefs(ident("entities"), ident("Entities"))

  writeData(data)

  return body
