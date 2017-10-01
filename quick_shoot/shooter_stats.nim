type
  ShooterWeapon* = object
    name*: string
    attackSpeed*: float
    damage*: int
    numBullets*: int
  ShooterStats* = ref object
    leftClickWeapon*: ShooterWeapon
    qWeapon*: ShooterWeapon
    gold*: int
    xp*: int

proc addGold*(stats: ShooterStats, gold: int) =
  stats.gold += gold

proc addXp*(stats: ShooterStats, xp: int) =
  stats.xp += xp

proc newShooterStats*(): ShooterStats =
  ShooterStats(
    leftClickWeapon: ShooterWeapon(
      name: "Gun",
      attackSpeed: 4.8,
      damage: 1,
      numBullets: 1,
    ),
    qWeapon: ShooterWeapon(
      name: "Spread",
      attackSpeed: 1.4,
      damage: 1,
      numBullets: 5,
    ),
    gold: 100,
  )
