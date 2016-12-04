import
  algorithm,
  macros,
  os,
  strutils,
  tables

import
  entity,
  jsonparse,
  option


type
  System = object
    id: int
    args: seq[string]
    filename: string
  SysTable = Table[string, System]
  Data = object
    update: SysTable
    draw: SysTable
const sysFile = "systems.json"

proc tryKey(json: JSON, key: string): Option[JSON] =
  assert json.kind == jsObject
  if json.obj.hasKey(key):
    makeJust(json.obj[key])
  else:
    makeNone[JSON]()

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

proc fromJSON(systems: var SysTable, json: JSON) =
  assert json.kind == jsObject
  systems = initTable[string, System](64)
  for k, v in json.obj:
    systems[k] = fromJSON[System](v)
proc fromJSON(system: var SysTable, json: Option[JSON]) =
  case json.kind
  of just:
    fromJSON(system, json.value)
  of none:
    system = initTable[string, System](64)
proc toJSON(systems: SysTable): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for k, v in systems:
    result.obj[k] = toJSON(v)

proc fromJSON(data: var Data, json: JSON) =
  assert json.kind == jsObject
  fromJSON(data.update, json.tryKey("update"))
  fromJSON(data.draw, json.tryKey("draw"))
proc toJSON(data: Data): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["update"] = data.update.toJSON()
  result.obj["draw"] = data.draw.toJSON()

proc readData(): Data =
  let json = readJSONFile(sysFile)
  return fromJSON[Data](json)

proc writeData(data: Data) =
  writeFile(sysFile, data.toJson.toPrettyString)

proc getNextId(data: Data): int =
  var ids: seq[int] = @[]
  for d in data.update.values:
    ids.add d.id
  for d in data.draw.values:
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

proc defineSystem_impl(body: NimNode, sysType: string): NimNode =
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

  var
    data = readData()
    systems = if sysType == "update": data.update else: data.draw

  let key = ($sysProc.name)[0..^2]
  if not systems.hasKey(key):
    let nextId = getNextId(data)
    systems[key] = System()
    systems[key].id = nextId

  var params = sysProc.params
  assert params[0].kind == nnkEmpty, "System " & key & " should not have a return value"
  if sysType == "update":
    params[0] = ident("Events")
  params.insert 1, newIdentDefs(ident("entities"), ident("Entities"))
  var paramStart = 2
  if sysType == "draw":
    params.insert 1, newIdentDefs(ident("renderer"), ident("RendererPtr"))
    paramStart += 1
  var args: seq[string] = @[]
  for i in paramStart..<params.len:
    let arg = params[i]
    args.add $arg[0].ident
  systems[key].args = args
  systems[key].filename = lineinfo(body).split("(")[0].replace("\\", by="/")

  if sysType == "update":
    data.update = systems
  else:
    data.draw = systems
  writeData(data)

  return sysProc

macro defineSystem*(body: untyped): untyped =
  defineSystem_impl(body, "update")

macro defineDrawSystem*(body: untyped): untyped =
  defineSystem_impl(body, "draw")

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
    game2 = ident("game2")
    renderer = ident("renderer")
  let
    retVal = newEmptyNode()
    gameParam = newIdentDefs(game, gameType)
    updateDef = newProc(ident("updateSystems"), [retVal, gameParam])
    rendererParam = newIdentDefs(renderer, ident("RendererPtr"))
    drawDef = newProc(ident("drawSystems"), [retVal, rendererParam, gameParam])

  for k, v in data.update:
    let
      sysName = ident(k)
      callNode = newCall(sysName, newDotExpr(game, ident("entities")))
    for arg in v.args:
      callNode.add newDotExpr(game, ident(arg))
    updateDef.body.add newCall(!"process", game, callNode)
  result.add updateDef

  for k, v in data.draw:
    let
      drawName = ident(k)
      callNode = newCall(drawName, renderer, newDotExpr(game, ident("entities")))
    for arg in v.args:
      callNode.add newDotExpr(game, ident(arg))
    drawDef.body.add callNode
  result.add drawDef
