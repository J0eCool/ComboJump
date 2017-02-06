type
  RoomKind* = enum
    roomNormal
    roomStart
    roomEnd
  Room* = object
    id*: int
    left*: int
    right*: int
    up*: int
    down*: int
    kind*: RoomKind
