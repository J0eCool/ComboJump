import
  algorithm,
  macros,
  strutils,
  tables

import
  entity,
  jsonparse


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
