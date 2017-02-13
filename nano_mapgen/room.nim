type
  DoorKind* = enum
    doorWall
    doorOpen
    doorEntrance
    doorExit
    doorLocked
  RoomKind* = enum
    roomNormal
    roomStart
    roomEnd
    roomKey
  Room* = object
    id*: int
    kind*: RoomKind
    x*: int
    y*: int
    left*: DoorKind
    right*: DoorKind
    up*: DoorKind
    down*: DoorKind
