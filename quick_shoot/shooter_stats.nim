import
  quick_shoot/[
    weapon,
  ]

type
  ShooterStats* = ref object
    leftClickWeapon*: ShooterWeapon
    qWeapon*: ShooterWeapon
    gold*: int
    xp*: int

proc addGold*(stats: ShooterStats, gold: int) =
  stats.gold += gold

proc addXp*(stats: ShooterStats, xp: int) =
  stats.xp += xp

proc resetWeapons*(stats: ShooterStats) =
  stats.leftClickWeapon.reset()
  stats.qWeapon.reset()

proc newShooterStats*(): ShooterStats =
  result = ShooterStats(
    leftClickWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        kind: straight,
        name: "Gun",
        attackSpeed: 4.8,
        damage: 1,
        numBullets: 1,
        maxAmmo: 12,
        reloadTime: 1.25,
    )),
    qWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        kind: spread,
        name: "Spread",
        attackSpeed: 1.4,
        damage: 1,
        numBullets: 5,
        maxAmmo: 3,
        reloadTime: 2.4,
    )),
    gold: 100,
  )
  result.resetWeapons()
