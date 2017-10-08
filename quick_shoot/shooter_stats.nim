import
  quick_shoot/[
    weapon,
  ],
  vec

type
  ShooterStats* = ref object
    leftClickWeapon*: ShooterWeapon
    qWeapon*: ShooterWeapon
    wWeapon*: ShooterWeapon
    gold*: int
    xp*: int

proc addGold*(stats: ShooterStats, gold: int) =
  stats.gold += gold

proc addXp*(stats: ShooterStats, xp: int) =
  stats.xp += xp

proc resetWeapons*(stats: ShooterStats) =
  stats.leftClickWeapon.reset()
  stats.qWeapon.reset()
  stats.wWeapon.reset()

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
    wWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        name: "Gatling",
        maxAmmo: 60,
        reloadTime: 3.0,
        damage: 1,
        attackSpeed: 12.0,
        numBullets: 1,
        bulletSpeed: 650.0,
        kind: gatling,
        numBarrels: 3,
        barrelRotateSpeed: 50.0,
        barrelOffset: 45.0,
        barrelSize: vec(5, 20),
    )),
    gold: 100,
  )
  result.resetWeapons()
