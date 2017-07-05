import
  algorithm,
  times

import
  file_util,
  jsonparse,
  mapgen/[
    tile,
  ],
  vec

type
  Tilemap* = object
    name*: string
    textures*: seq[string]
    decorationGroups*: seq[DecorationGroup]
  DecorationGroup* = object
    blacklist*: seq[SubTileKind]
    textures*: seq[string]
    offsets*: seq[Vec]
    maxCount*: int

autoObjectJsonProcs(DecorationGroup)
autoObjectJsonProcs(Tilemap)

proc cmp(a, b: Tilemap): int =
  cmp(a.name, b.name)

var
  nextWalkTilemapTime: float
  cachedTilemapTextures = newSeq[Tilemap]()
proc allTilemaps*(): seq[Tilemap] =
  let curTime = epochTime()
  if curTime < nextWalkTilemapTime:
    return cachedTilemapTextures
  nextWalkTilemapTime = curTime + 1.0

  let paths = filesInDirWithExtension("assets/tilemaps", ".tilemap")
  result = @[]
  for path in paths:
    var tilemap: Tilemap
    tilemap.fromJson(readJsonFile(path))
    result.add tilemap
  assert result.len > 0, "Need to have at least one tilemap texture"
  result.sort(cmp)
  cachedTilemapTextures = result

proc tilemapFromName*(name: string): Tilemap =
  for tilemap in allTilemaps():
    if tilemap.name == name:
      return tilemap
  assert false, "Unable to find tilemap: " & name

proc isKindAllowed*(group: DecorationGroup, kind: SubTileKind): bool =
  if kind == tileNone:
    return false
  if group.blacklist != nil and kind in group.blacklist:
    return false
  return true

