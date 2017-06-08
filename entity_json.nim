import
  macros,
  os,
  tables

import
  entity,
  jsonparse,
  vec

macro importAllComponents(): untyped =
  result = newNimNode(nnkStmtList)
  for f in walkDir("component"):
    result.add newTree(nnkImportStmt, ident(f.path))

importAllComponents()

method jsonVal*(component: Component): Json {.base.}
method loadJson*(component: Component, json: Json) {.base.}
macro declareToJsonMethods(): untyped =
  var data = readComponentData()

  const implementedNames = [
    "Collider",
    "Component",
    "Damage",
    "GridControl",
    "Health",
    "LimitedQuantity",
    "Key",
    "KeyCollection",
    "LockedDoor",
    "Mana",
    "Movement",
    "PlayerHealth",
    "PlayerMana",
    "PlatformerControl",
    "SpellShooter",
    "Sprite",
    "Targeting",
    "Transform",
  ]
  result = newStmtList()
  for name, _ in data:
    if name notin implementedNames:
      continue
    let toJsonMethod = newProc(postfix(ident("jsonVal"), "*"),
      params=[
        ident("Json"),
        newIdentDefs(ident("component"), ident(name)),
      ],
      procType=nnkMethodDef)
    toJsonMethod.body.add newCall(
      ident("toJson"),
      newTree(nnkBracketExpr, ident("component")),
    )
    result.add toJsonMethod

    let loadJsonMethod = newProc(postfix(ident("loadJson"), "*"),
      params=[
        newEmptyNode(),
        newIdentDefs(ident("component"), ident(name)),
        newIdentDefs(ident("json"), ident("Json")),
      ],
      procType=nnkMethodDef)
    loadJsonMethod.body.add newCall(
      ident("fromJson"),
      newTree(nnkBracketExpr, ident("component")),
      ident("json"),
    )
    result.add loadJsonMethod
  
  let
    toComponentProc = newProc(postfix(ident("stringToComponent"), "*"),
      params=[
        ident("Component"),
        newIdentDefs(ident("str"), ident("string")),
      ])
    caseStmt = newTree(nnkCaseStmt, ident("str"))
  for name, _ in data:
    if name notin implementedNames:
      continue
    caseStmt.add newTree(
      nnkOfBranch,
      newLit(name),
      newCall(ident(name)),
    )
  caseStmt.add newTree(nnkElse, newNilLit())
  toComponentProc.body.add caseStmt
  result.add toComponentProc

declareToJsonMethods()

proc toJson*(entity: Entity): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  var componentJson = Json(kind: jsObject, obj: initTable[string, Json]())
  for c in entity.components:
    componentJson.obj[typeId(c)] = jsonVal(c)
  result.obj["components"] = componentJson
  result.obj["name"] = entity.name.toJson()
proc fromJson*(entity: var Entity, json: Json) =
  assert json.kind == jsObject
  var components = newSeq[Component]()
  for k, v in json.obj["components"].obj:
    let c = stringToComponent(k)
    assert c != nil, "Invalid component type: " & k
    loadJson(c, v)
    components.add c
  let name = json.obj["name"].str
  entity = newEntity(name, components)
