import vec

type
  Decoration* = object
    texture*: string
    offset*: Vec

  TileState* = enum
    tileFilled
    tileRandom

  GridTile* = set[TileState]

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
