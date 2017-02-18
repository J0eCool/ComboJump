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
proc toJSON*(entity: Entity): JSON

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
      newTree(nnkBracketExpr, ident("component"))
    )
    result.add toJsonMethod
  echo result.repr

declareToJSONMethods()

macro getField(obj: typed, field: string): untyped =
  newDotExpr(obj, ident(field.strVal))
macro setField(obj: typed, field: string, value: typed): untyped =
  newAssignment(newDotExpr(obj, field), value)

proc toJSON*(entity: Entity): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  for c in entity.components:
    result.obj[typeId(c)] = jsonVal(c)

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
