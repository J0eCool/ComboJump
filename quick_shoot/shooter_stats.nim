import
  quick_shoot/[
    weapon,
  ],
  vec

type
  ShooterStats* = ref object
    leftClickWeapon*: ShooterWeapon
    rightClickWeapon*: ShooterWeapon
    qWeapon*: ShooterWeapon
    wWeapon*: ShooterWeapon
    maxAmmo*: int

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
        ammoCost: 1,
        damage: 1,
        attackSpeed: 3.0,
        numBullets: 1,
        bulletSpeed: 800.0,
        kind: straight,
        totalSpacing: 15.0,
    )),
    rightClickWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        name: "Spread",
        ammoCost: 2,
        damage: 2,
        attackSpeed: 2.5,
        numBullets: 4,
        bulletSpeed: 500.0,
        kind: spread,
        totalAngle: 50.0,
    )),
    qWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
        name: "OtherSpread",
        ammoCost: 1,
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
        ammoCost: 1,
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
    maxAmmo: 100,
    gold: 100,
  )
  result.resetWeapons()
