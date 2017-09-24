from sdl2 import RendererPtr

import
  component/sprite,
  mapgen/[
    tile,
    tile_room,
    tilemap,
  ],
  camera,
  drawing,
  rect,
  resources,
  vec

proc clipRect(subtile: SubTileKind, sprite: SpriteData): Rect =
  let
    tileSize = sprite.size.size / vec(5, 3)
    tilePos =
      case subtile
      of tileUL:    vec(0, 0)
      of tileUC:    vec(1, 0)
      of tileUR:    vec(2, 0)
      of tileCL:    vec(0, 1)
      of tileCC:    vec(1, 1)
      of tileCR:    vec(2, 1)
      of tileDL:    vec(0, 2)
      of tileDC:    vec(1, 2)
      of tileDR:    vec(2, 2)
      of tileCorDR: vec(3, 0)
      of tileCorDL: vec(4, 0)
      of tileCorUR: vec(3, 1)
      of tileCorUL: vec(4, 1)
      else:         vec()
  rect(tileSize * tilePos, tileSize)

proc loadSprite(subtile: SubTile, resources: ResourceManager, renderer: RendererPtr): SpriteData =
  let tilemapName = "tilemaps/" & subtile.texture
  resources.loadSprite(tilemapName, renderer)

proc drawRoom*(renderer: RendererPtr, resources: ResourceManager, room: TileRoom, pos, tileSize: Vec) =
  for x in 0..<room.w:
    for y in 0..<room.h:
      let tile = room.tiles[x][y]
      if tile.kind != tileNone:
        let
          sprite = tile.loadSprite(resources, renderer)
          r = tileSize.gridRect(x, y, isSubtile=true) + pos
          scale = tileSize.x * 5 / sprite.size.size.x / 2
        renderer.draw(sprite, r, tile.kind.clipRect(sprite))
        for deco in tile.decorations:
          let
            decoSprite = resources.loadSprite("tilemaps/" & deco.texture, renderer)
            decoRect = rect(r.pos + scale * deco.offset,
                            scale * decoSprite.size.size)
          renderer.draw(decoSprite, decoRect)
