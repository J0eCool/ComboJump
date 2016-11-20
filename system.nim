import
  algorithm,
  macros,
  strutils,
  tables

import
  entity,
  jsonparse


type
  System = object
    id: int
    args: seq[string]
  Data = Table[string, System]
const sysFile = "systems.json"

proc fromJSON(system: var System, json: JSON) =
  assert json.kind == jsObject
  system.id = fromJSON[int](json.obj["id"])
  system.args = fromJSON[seq[string]](json.obj["args"])
proc toJSON(system: System): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["id"] = system.id.toJSON()
  result.obj["args"] = system.args.toJSON()

proc fromJSON(data: var Data, json: JSON) =
  data = initTable[string, System](64)
  assert json.kind == jsObject
  for k, v in json.obj:
    data[k] = fromJSON[System](v)
proc toJSON(data: Data): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for k, v in data:
    result.obj[k] = toJSON(v)

proc readData(): Data =
  let json = readJSONFile(sysFile)
  return fromJSON[Data](json)

proc writeData(data: Data) =
  writeFile(sysFile, data.toJson.toPrettyString)

proc getNextId(data: Data): int =
  var ids: seq[int] = @[]
  for d in data.values:
    ids.add d.id
  ids.sort(cmp)
  for x in ids:
    if x > result:
      return
    result += 1

macro defineSystem*(body: untyped): untyped =
  var data = readData()
  let key = ($body[0].name)[0..^2]
  if not data.hasKey(key):
    let nextId = getNextId(data)
    data[key] = System()
    data[key].id = nextId

  var ps = body[0].params
  assert ps[0].kind == nnkEmpty, "System " & key & " should not have a return value"
  ps[0] = ident("Events")
  ps.insert 1, newIdentDefs(ident("entities"), ident("Entities"))
  var args: seq[string] = @[]
  for i in 2..<ps.len:
    args.add $ps[i][0].ident
  data[key].args = args

  writeData(data)

  return body

proc addSystemCalls*(stmtList: NimNode, game: NimNode) =
  let data = readData()
  let entities = newDotExpr(game, newIdentNode(!"entities"))
  for k, v in data:
    let
      sysName = newIdentNode(k)
      callNode = newCall(sysName, entities)
    for arg in v.args:
      callNode.add newDotExpr(game, newIdentNode(arg))
    let
      processCall = newCall(!"process", game, callNode)
      declaredCall = newCall(!"declared", sysName)
    var whenNode = newNimNode(nnkWhenStmt)
    whenNode.add newNimNode(nnkElifBranch).add(declaredCall).add(processCall)
    stmtList.add whenNode
