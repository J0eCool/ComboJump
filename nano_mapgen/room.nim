type
  DoorKind* = enum
    doorWall
    doorOpen
    doorExit
  RoomKind* = enum
    roomNormal
    roomStart
    roomEnd
  Room* = object
    id*: int
    kind*: RoomKind
    x*: int
    y*: int
    left*: DoorKind
    right*: DoorKind
    up*: DoorKind
    down*: DoorKind
