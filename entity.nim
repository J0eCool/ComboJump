import macros, sdl2

import component/component, vec

type Entity* = ref object of RootObj
  components: seq[Component]

proc newEntity*(components: seq[Component]): Entity =
  new result
  result.components = components

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

macro forComponents*(entities, e: expr, components: seq[expr], body: stmt): stmt {.immediate.} =
  assert(components.len mod 2 == 0, "Need a name and identifier for each component")
  result = newNimNode(nnkForStmt)
  result.add(e)
  result.add(entities)
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
