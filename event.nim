import
  entity,
  util

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

proc process*(entities: var Entities, events: Events) =
  for event in events:
    case event.kind
    of addEntity:
      entities.add event.entity
    of removeEntity:
      entities.remove event.entity
    of loadStage:
      entities = event.stage
