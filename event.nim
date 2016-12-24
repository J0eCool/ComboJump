import entity

type
  EventKind* = enum
    addEntity
    removeEntity
    loadStage
  Event* = object
    case kind*: EventKind
    of addEntity, removeEntity:
      entity*: Entity
    of loadStage:
      stage*: Entities
  Events* = seq[Event]
