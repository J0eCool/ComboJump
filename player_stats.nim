import tables

import
  jsonparse

type PlayerStats* = object
  level*: int
  xp*: int
  shouldSave*: bool

proc fromJson*(stats: var PlayerStats, json: Json) =
  assert json.kind == jsObject
  stats.level.fromJson(json.obj["level"])
  stats.xp.fromJson(json.obj["xp"])
proc toJson*(stats: PlayerStats): Json =
  result = Json(kind: jsObject, obj: initTable[string, Json]())
  result.obj["level"] = stats.level.toJson()
  result.obj["xp"] = stats.xp.toJson()

proc newPlayerStats*(): PlayerStats =
  PlayerStats(
    level: 1,
  )

proc xpToNextLevel*(stats: PlayerStats): int =
  let lv = stats.level - 1
  36 + 12 * lv + (lv * lv div 2)

proc addXp*(stats: var PlayerStats, xp: int) =
  stats.xp += xp
  while stats.xp >= stats.xpToNextLevel():
    stats.xp -= stats.xpToNextLevel()
    stats.level += 1
  stats.shouldSave = true

proc maxHealth*(stats: PlayerStats): int =
  100 + 10 * (stats.level - 1)

proc maxMana*(stats: PlayerStats): int =
  50 + 5 * (stats.level - 1)

proc manaRegen*(stats: PlayerStats): float =
  stats.maxMana.float * 0.15

proc castSpeed*(stats: PlayerStats): float =
  1.0 + 0.02 * (stats.level - 1).float

proc damage*(stats: PlayerStats): float =
  1.0 + 0.075 * (stats.level - 1).float
