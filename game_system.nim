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
    types: seq[string]
    filename: string
    priority: int
  SysTable = Table[string, System]
  Data = object
    update: SysTable
    draw: SysTable

  CallPair = tuple[priority: int, callNode: NimNode]

const
  sysFile = "systems.json"
  useDylibs = false

proc tryKey(json: Json, key: string): Option[Json] =
  assert json.kind == jsObject
  if json.obj.hasKey(key):
    makeJust(json.obj[key])
  else:
    makeNone[Json]()

proc fromJson(system: var System, json: Json) =
  assert json.kind == jsObject
  system.id = fromJson[int](json.obj["id"])
  system.args = fromJson[seq[string]](json.obj["args"])
  system.types = fromJson[seq[string]](json.obj["types"])
  system.filename = fromJson[string](json.obj.getOrDefault("filename"))
  system.priority = fromJson[int](json.obj["priority"])
proc toJson(system: System): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  result.obj["id"] = system.id.toJson()
  result.obj["args"] = system.args.toJson()
  result.obj["types"] = system.types.toJson()
  result.obj["filename"] = system.filename.toJson()
  result.obj["priority"] = system.priority.toJson()

proc fromJson(systems: var SysTable, json: Json) =
  assert json.kind == jsObject
  systems = initTable[string, System](64)
  for k, v in json.obj:
    systems[k] = fromJson[System](v)
proc fromJson(system: var SysTable, json: Option[Json]) =
  case json.kind
  of just:
    fromJson(system, json.value)
  of none:
    system = initTable[string, System](64)
proc toJson(systems: SysTable): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  for k, v in systems:
    result.obj[k] = toJson(v)

proc fromJson(data: var Data, json: Json) =
  assert json.kind == jsObject
  fromJson(data.update, json.tryKey("update"))
  fromJson(data.draw, json.tryKey("draw"))
proc toJson(data: Data): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  result.obj["update"] = data.update.toJson()
  result.obj["draw"] = data.draw.toJson()

proc readData(): Data =
  let json = readJsonFile(sysFile)
  return fromJson[Data](json)

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

proc toLowerFirst(str: string): string =
  str[0..1].toLowerAscii & str[2..^0]

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
  var
    sysProc: NimNode = nil
    components: seq[string] = nil
    priority = 0
  for n in body:
    if n.kind == nnkProcDef:
      assert sysProc == nil, "Only expecting one proc per system"
      sysProc = n
    else:
      assert n.kind == nnkAsgn
      let metaKind = $n[0]
      case metaKind
      of "components":
        let bracket = n[1]
        assert bracket.kind == nnkBracket, "components metadata must be an array literal"
        components = newSeq[string]()
        for c in bracket:
          components.add $c.ident
      of "priority":
        let val = n[1]
        if val.kind == nnkIntLit:
          priority = val.intVal.int
        elif val.kind == nnkPrefix and val[0].ident == !"-":
          priority = -val[1].intVal.int
        else:
          assert false, "Invalid priority:\n" & val.treeRepr
      else:
        assert false, "Unrecognized system metadata: " & metaKind
  assert sysProc != nil, "Must find proc in system"

  # var
  #   data = readData()
  #   systems = if sysType == "update": data.update else: data.draw

  let key = ($sysProc.name)[0..^2]
  # if not systems.hasKey(key):
  #   let nextId = getNextId(data)
  #   systems[key] = System()
  #   systems[key].id = nextId
  #   systems[key].filename = lineinfo(body).split("(")[0].replace("\\", by="/")

  var params = sysProc.params
  assert params[0].kind == nnkEmpty, "System " & key & " should not have a return value"
  if sysType == "update":
    params[0] = ident("Events")
  params.insert 1, newIdentDefs(ident("entities"), ident("Entities"))
  var paramStart = 2
  if sysType == "draw":
    params.insert 1, newIdentDefs(ident("renderer"), ident("RendererPtr"))
    paramStart += 1
  # var
  #   args: seq[string] = @[]
  #   types: seq[string] = @[]
  # for i in paramStart..<params.len:
  #   let arg = params[i]
  #   args.add $arg[0].ident
  #   if arg[1].kind == nnkVarTy:
  #     types.add "var " & $arg[1][0].ident
  #   else:
  #     types.add $arg[1].ident
  # systems[key].args = args
  # systems[key].types = types
  # systems[key].priority = priority

  # if sysType == "update":
  #   data.update = systems
  # else:
  #   data.draw = systems
  # writeData(data)

  if components != nil:
    let
      baseBody = sysProc.body
      forComponents = newCall("forComponents", ident("entities"), ident("entity"))
    sysProc.body = newStmtList()
    let componentList = newTree(nnkBracket)
    for c in components:
      componentList.add ident(c)
      componentList.add ident(c.toLowerFirst)
    if sysType == "update":
      sysProc.body.add newAssignment(ident("result"), prefix(newTree(nnkBracket), "@"))
    forComponents.add componentList
    forComponents.add baseBody
    sysProc.body.add forComponents

  when useDylibs:
    sysProc.addPragma(ident("exportc"))
    sysProc.addPragma(ident("dynlib"))

  return sysProc

macro defineSystem*(body: untyped): untyped =
  defineSystem_impl(body, "update")

macro defineDrawSystem*(body: untyped): untyped =
  defineSystem_impl(body, "draw")

macro importAllSystems*(): untyped =
  result = newNimNode(nnkStmtList)
  for f in walkDir("component"):
    result.add newTree(nnkImportStmt, ident(f.path))
  for f in walkDir("menu"):
    result.add newTree(nnkImportStmt, ident(f.path))
  for f in walkDir("system"):
    result.add newTree(nnkImportStmt, ident(f.path))

proc basename(filename: string): string =
  let parts = filename.split("/")
  if parts.len == 1: filename else: parts[parts.len - 1]

macro defineDylibs*(): untyped =
  if not useDylibs:
    return newStmtList()
  result = newNimNode(nnkVarSection)
  let data = readData()
  for sysName, v in data.update:
    let dylibFile = "out/" & v.filename.basename[0..^5] & ".dll"
    var callNode = newTree(nnkCall,
      newTree(nnkBracketExpr,
        ident("newSingleSymDylib"),
        newTree(nnkProcTy,
          newTree(nnkFormalParams,
            ident("Events"),
            newTree(nnkIdentDefs,
              ident("entities"),
              ident("Entities"),
              newEmptyNode(),
            ),
          ),
          newTree(nnkPragma, ident("nimcall")),
        ),
      ),
      newLit(dylibFile),
      newLit(sysName),
    )
    for i in 0..<v.args.len:
      let
        arg = v.args[i]
        tyStr = v.types[i]
        ty =
          if tyStr[0..3] != "var ":
            ident(tyStr)
          else:
            newTree(nnkVarTy, ident(tyStr[4..^0]))
      callNode[0][1][0].add newTree(nnkIdentDefs, ident(arg), ty, newEmptyNode())
    result.add newIdentDefs(ident(sysName & "Dylib"), newEmptyNode(), callNode)

proc sortCallPairs(list: var seq[CallPair]) =
  list.sort(
    proc(a, b: CallPair): int =
      -cmp[int](a.priority, b.priority)
  )

macro defineSystemCalls*(gameType: typed): untyped =
  result = newNimNode(nnkStmtList)
  let
    data = readData()
    game = ident("game")
    renderer = ident("renderer")
  let
    retVal = newEmptyNode()
    gameParam = newIdentDefs(game, gameType)
    updateDef = newProc(ident("updateSystems"), [retVal, gameParam])
    rendererParam = newIdentDefs(renderer, ident("RendererPtr"))
    drawDef = newProc(ident("drawSystems"), [retVal, rendererParam, gameParam])

  var updatePairs = newSeq[CallPair]()
  for k, v in data.update:
    when useDylibs:
      let
        sysName = ident(k & "Dylib")
        loadNode = newCall(!"tryLoadLib", sysName)
        callNode = newCall(newCall(ident("getSym"), sysName), newDotExpr(game, ident("entities")))
      updateDef.body.add loadNode
    else:
      let
        sysName = ident(k)
        callNode = newCall(sysName, newDotExpr(game, ident("entities")))
    for arg in v.args:
      callNode.add newDotExpr(game, ident(arg))
    updatePairs.add((v.priority, newCall(!"process", game, callNode)))
  updatePairs.sortCallPairs()
  for p in updatePairs:
    updateDef.body.add p.callNode
  result.add updateDef

  var drawPairs = newSeq[CallPair]()
  for k, v in data.draw:
    let
      drawName = ident(k)
      callNode = newCall(drawName, renderer, newDotExpr(game, ident("entities")))
    for arg in v.args:
      callNode.add newDotExpr(game, ident(arg))
    drawPairs.add((v.priority, callNode))
  drawPairs.sortCallPairs()
  for p in drawPairs:
    drawDef.body.add p.callNode
  result.add drawDef
