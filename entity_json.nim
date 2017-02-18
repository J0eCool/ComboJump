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

# importAllComponents()
import component/[transform, damage]

proc toJSON*[T: ComponentObj](component: T): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for k, v in component.fieldPairs:
    when k != "entity":
      result.obj[k] = toJSON(v)
proc fromJSON*[T: ComponentObj](component: var T, json: JSON) =
  assert json.kind == jsObject
  for k, val in component.fieldPairs:
    when k != "entity":
      val.fromJSON(json.obj[k])

proc toJSON*(entity: Entity): JSON
proc fromJSON*(entity: var Entity, json :JSON)

macro declareToJSONMethods(): untyped =
  var data = readComponentData()

  const implementedNames = [
    "Component",
    "Damage",
    "Transform",
  ]
  result = newStmtList()
  for name, _ in data:
    if name notin implementedNames:
      continue
    let toJsonMethod = newProc(postfix(ident("jsonVal"), "*"),
      params=[
        ident("JSON"),
        newIdentDefs(ident("component"), ident(name)),
      ],
      procType=nnkMethodDef)
    toJsonMethod.body.add newCall(
      newTree(nnkBracketExpr, ident("toJSON"), ident(name & "Obj")),
      newTree(nnkBracketExpr, ident("component")),
    )
    result.add toJsonMethod

    let loadJsonMethod = newProc(postfix(ident("loadJson"), "*"),
      params=[
        newEmptyNode(),
        newIdentDefs(ident("component"), ident(name)),
        newIdentDefs(ident("json"), ident("JSON")),
      ],
      procType=nnkMethodDef)
    loadJsonMethod.body.add newCall(
      newTree(nnkBracketExpr, ident("fromJSON"), ident(name & "Obj")),
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

declareToJSONMethods()

proc toJSON*(entity: Entity): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for c in entity.components:
    result.obj[typeId(c)] = jsonVal(c)
proc fromJSON*(entity: var Entity, json: JSON) =
  assert json.kind == jsObject
  var components = newSeq[Component]()
  for k, v in json.obj:
    let c = stringToComponent(k)
    loadJson(c, v)
    components.add c
  entity = newEntity("LOADED", components)

let
  a = Transform(
    pos: vec(2, 3),
    size: vec(3, 4),
  )
  b = Damage(
    damage: 12,
  )
  ent = newEntity("test", [a, b])

echo toJSON(ent)

var e2 = Entity()
e2.fromJSON(deserializeJSON("""{"Damage":{"damage":"91"}}"""))
echo e2, e2.getComponent(Damage)[], e2.getComponent(Transform)==nil
