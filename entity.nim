import
  algorithm,
  macros,
  tables

import
  jsonparse,
  vec

type
  Entity* = ref object of RootObj
    id*: int
    name*: string
    components*: seq[Component]
    parent*: Entity
    children: seq[Entity]

  ComponentObj* = object of RootObj
    entity*: Entity
  Component* = ref ComponentObj

  Entities* = seq[Entity]

var nextId = 0
proc newEntity*(name: string, components: openarray[Component], children: openarray[Entity] = []): Entity =
  new result
  result.id = nextId
  result.name = name
  result.components = @components
  for c in result.components:
    c.entity = result
  result.children = @children
  for e in result.children:
    e.parent = result
  nextId += 1

proc C*(c: Component): seq[Component] =
  @[c]

proc getComponent_impl[T: Component](entity: Entity): T =
  for c in entity.components:
    if c of T:
      return T(c)

template getComponent*(entity, t: expr): expr =
  getComponent_impl[t](entity)

template withComponent*(entity, t, name: expr, body: stmt): stmt {.immediate.} =
  let name = entity.getComponent(t)
  if name != nil:
    body

iterator flatten*(entities: Entities): Entity =
  var toTraverse = entities
  while toTraverse.len > 0:
    let
      idx = toTraverse.len - 1
      e = toTraverse[idx]
    toTraverse.del(idx)
    yield e
    if e.children.len > 0:
      toTraverse &= e.children

macro forComponents*(entities, e: expr, components: seq[expr], body: stmt): stmt {.immediate.} =
  assert(components.len mod 2 == 0, "Need a name and identifier for each component")
  result = newNimNode(nnkForStmt)
  result.add(e)
  result.add(newCall(!"flatten", entities))
  let forList = newStmtList()
  for i in 0..<components.len div 2:
    let
      componentType = components[2*i]
      componentName = components[2*i + 1]
      callNode = newCall(!"getComponent", e, componentType)
      letNode = newLetStmt(componentName, callNode)
      ifCond = newCall(!"==", componentName, newNilLit())
      continueNode = newNimNode(nnkContinueStmt).add(newEmptyNode())
      ifNode = newIfStmt((ifCond, continueNode))
    forList.add(letNode)
    forList.add(ifNode)
  forList.add(body)
  result.add(forList)

proc firstEntityByName*(entities: seq[Entity], name: string): Entity =
  for e in entities.flatten:
    if e.name == name:
      return e

proc firstComponent_impl[T](entities: Entities): T =
  for e in entities.flatten:
    let c = e.getComponent(T)
    if c != nil:
      return c
  return nil

template firstComponent*(entities: Entities, t: expr): expr =
  firstComponent_impl[t](entities)

proc `$`*(e: Entity): string =
  if e != nil:
    e.name & " (id=" & $e.id & ")"
  else:
    "(nil entity)"

iterator items*(entity: Entity): Entity =
  for e in entity.children:
    yield e

type ComponentData* = Table[string, int]
const componentFile = "components.json"
proc readComponentData*(): ComponentData =
  result = initTable[string, int]()
  let json = readJSONFile(componentFile)
  if json.kind == jsError:
    return
  result.fromJSON(json)
proc writeComponentData(data: ComponentData) =
  writeFile(componentFile, data.toJson.toPrettyString)

proc getNextId(data: ComponentData): int =
  var ids = newSeq[int]()
  for id in data.values:
    ids.add id
  ids.sort(cmp)
  result = 1
  for x in ids:
    if x > result:
      return
    result += 1

macro defineComponent*(component: untyped): untyped =
  var data = readComponentData()
  let name = $component.ident
  if not data.hasKey(name):
    data[name] = data.getNextId()
  data.writeComponentData()

  let idMethod = newProc(postfix(ident("typeId"), "*"),
    params=[
      ident("string"),
      newIdentDefs(ident("component"), ident(name)),
    ],
    procType=nnkMethodDef)
  idMethod.body.add newLit(name)

  newStmtList(
    idMethod
  )
defineComponent(Component)
