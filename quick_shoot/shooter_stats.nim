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
        name: "Gun",
        maxAmmo: 16,
        reloadTime: 1.5,
        damage: 1,
        attackSpeed: 6.0,
        numBullets: 1,
        bulletSpeed: 800.0,
        kind: straight,
        totalSpacing: 15.0,
    )),
    qWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        name: "Spread",
        maxAmmo: 3,
        reloadTime: 3.0,
        damage: 1,
        attackSpeed: 1.6,
        numBullets: 7,
        bulletSpeed: 500.0,
        kind: spread,
        totalAngle: 60.0,
    )),
    gold: 100,
  )
  result.resetWeapons()
