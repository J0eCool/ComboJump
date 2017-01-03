type PlayerStats* = object
  level*: int
  xp*: int

proc newPlayerStats*(): PlayerStats =
  PlayerStats(
    level: 1,
  )

proc xpToNextLevel*(stats: PlayerStats): int =
  let lv = stats.level - 1
  36 + 12 * lv + (lv * lv div 2)

proc maxHealth*(stats: PlayerStats): int =
  100 + 10 * (stats.level - 1)

proc maxMana*(stats: PlayerStats): int =
  50 + 5 * (stats.level - 1)

proc addXp*(stats: var PlayerStats, xp: int) =
  stats.xp += xp
  while stats.xp >= stats.xpToNextLevel():
    stats.xp -= stats.xpToNextLevel()
    stats.level += 1
