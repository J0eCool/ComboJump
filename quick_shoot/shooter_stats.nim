type
  ShooterWeaponInfo* = object
    name*: string
    attackSpeed*: float
    damage*: int
    numBullets*: int
  ShooterWeapon* = ref object
    info*: ShooterWeaponInfo
    cooldown*: float
  ShooterStats* = ref object
    leftClickWeapon*: ShooterWeapon
    qWeapon*: ShooterWeapon
    gold*: int
    xp*: int

proc addGold*(stats: ShooterStats, gold: int) =
  stats.gold += gold

proc addXp*(stats: ShooterStats, xp: int) =
  stats.xp += xp

proc reset(weapon: var ShooterWeapon) =
  weapon.cooldown = 0.0

proc resetWeapons*(stats: ShooterStats) =
  stats.leftClickWeapon.reset()
  stats.qWeapon.reset()

proc newShooterStats*(): ShooterStats =
  result = ShooterStats(
    leftClickWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        name: "Gun",
        attackSpeed: 4.8,
        damage: 1,
        numBullets: 1,
    )),
    qWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        name: "Spread",
        attackSpeed: 1.4,
        damage: 1,
        numBullets: 5,
    )),
    gold: 100,
  )
  result.resetWeapons()
