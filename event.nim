import entity

type
  EventKind* = enum
    addEntity
    removeEntity
  Event* = object
    case kind*: EventKind
    of addEntity, removeEntity:
      entity*: Entity
