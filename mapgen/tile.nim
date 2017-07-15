import vec

type
  Decoration* = object
    texture*: string
    offset*: Vec

  GridTile* = enum
    tileEmpty
    tileFilled
    tileRandom
    tileRandomGroup
    tileExit

  SubTileKind* = enum
    tileNone
    tileUL
    tileUC
    tileUR
    tileCL
    tileCC
    tileCR
    tileDL
    tileDC
    tileDR
    tileCorUL
    tileCorUR
    tileCorDL
    tileCorDR

  SubTile* = object
    kind*: SubTileKind
    texture*: string
    decorations*: seq[Decoration]
