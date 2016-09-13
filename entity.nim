import sdl2

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
