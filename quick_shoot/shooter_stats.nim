type
  ShooterStats* = ref object
    attackSpeed*: float
    damage*: int
    numBullets*: int
    gold*: int
    xp*: int

proc addGold*(stats: ShooterStats, gold: int) =
  stats.gold += gold

proc addXp*(stats: ShooterStats, xp: int) =
  stats.xp += xp
