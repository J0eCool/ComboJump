import
  algorithm,
  macros,
  os,
  strutils,
  tables

import
  entity,
  jsonparse


type
  System = object
    id: int
    args: seq[string]
    filename: string
  Data = Table[string, System]
const sysFile = "systems.json"

proc fromJSON(system: var System, json: JSON) =
  assert json.kind == jsObject
  system.id = fromJSON[int](json.obj["id"])
  system.args = fromJSON[seq[string]](json.obj["args"])
  system.filename = fromJSON[string](json.obj.getOrDefault("filename"))
proc toJSON(system: System): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["id"] = system.id.toJSON()
  result.obj["args"] = system.args.toJSON()
  result.obj["filename"] = system.filename.toJSON()

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

proc getBaseType(t: NimNode): NimNode =
  result = t
  while result.kind == nnkBracketExpr:
    result = result[1]
  assert result.kind == nnkSym

proc walkHierarchy(t: NimNode): seq[NimNode] =
  result = @[t.getBaseType]
  while $result[^1].symbol != "RootObj":
    let td = result[^1].symbol.getImpl
    result.add td[2][0][1][0]

macro defineSystem*(body: untyped): untyped =
  var sysProc: NimNode = nil
  for n in body:
    if n.kind == nnkProcDef:
      assert sysProc == nil, "Only expecting one proc per system"
      sysProc = n
    else:
      assert n.kind == nnkAsgn
      let metaKind = $n[0]
      case metaKind
      of "components":
        discard
      else:
        assert false, "Unrecognized system metadata: " & metaKind
  assert sysProc != nil, "Must find proc in system"

  var data = readData()
  let key = ($sysProc.name)[0..^2]
  if not data.hasKey(key):
    let nextId = getNextId(data)
    data[key] = System()
    data[key].id = nextId

  var ps = sysProc.params
  assert ps[0].kind == nnkEmpty, "System " & key & " should not have a return value"
  ps[0] = ident("Events")
  ps.insert 1, newIdentDefs(ident("entities"), ident("Entities"))
  var args: seq[string] = @[]
  for i in 2..<ps.len:
    let arg = ps[i]
    args.add $arg[0].ident
  data[key].args = args
  data[key].filename = lineinfo(body).split("(")[0]

  writeData(data)

  return sysProc

macro importAllSystems*(): untyped =
  result = newNimNode(nnkStmtList)
  for f in walkDir("component"):
    result.add newTree(nnkImportStmt, ident(f.path))
  for f in walkDir("system"):
    result.add newTree(nnkImportStmt, ident(f.path))

macro defineSystemCalls*(gameType: typed): untyped =
  result = newNimNode(nnkStmtList)
  let
    data = readData()
    game = ident("game")
    entities = newDotExpr(game, ident("entities"))
  let
    retVal = newEmptyNode()
    gameParam = newIdentDefs(game, gameType)
    procDef = newProc(ident("updateSystems"), [retVal, gameParam])
  for k, v in data:
    let
      sysName = ident(k)
      callNode = newCall(sysName, entities)
    for arg in v.args:
      callNode.add newDotExpr(game, ident(arg))
    procDef.body.add newCall(!"process", game, callNode)
  result.add procDef
