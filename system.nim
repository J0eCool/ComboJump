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

proc fromJSON(data: var Data, json: JSON) =
  data = initTable[string, int](64)
  assert json.kind == jsObject
  for k, v in json.obj:
    data[k] = fromJSON[int](v)

proc toJSON(data: Data): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for k, v in data:
    result.obj[k] = toJSON(v)

proc readData(): Data =
  let json = readJSONFile(sysFile)
  return fromJSON[Data](json)

proc writeData(data: Data) =
  writeFile(sysFile, $data.toJson)

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
