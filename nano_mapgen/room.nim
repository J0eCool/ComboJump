type
  DoorKind* = enum
    doorWall
    doorOpen
  Door* = object
    kind*: DoorKind
    room*: int
  RoomKind* = enum
    roomNormal
    roomStart
    roomEnd
  Room* = object
    id*: int
    left*: Door
    right*: Door
    up*: Door
    down*: Door
    kind*: RoomKind
