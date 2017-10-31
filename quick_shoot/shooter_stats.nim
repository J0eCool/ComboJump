import
  quick_shoot/[
    equipment,
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

    equipment*: Equipment

    gold*: int
    xp*: int

proc addGold*(stats: ShooterStats, gold: int) =
  stats.gold += gold

proc addXp*(stats: ShooterStats, xp: int) =
  stats.xp += xp

proc resetWeapons*(stats: ShooterStats) =
  proc setSlot(slot: var ShooterWeapon, index: int) =
    if index >= stats.equipment.weapons.len:
      return
    slot = ShooterWeapon(info: stats.equipment.weapons[index])
    slot.reset()

  stats.leftClickWeapon.setSlot(0)
  stats.rightClickWeapon.setSlot(1)
  stats.qWeapon.setSlot(2)
  stats.wWeapon.setSlot(3)

proc newShooterStats*(): ShooterStats =
  result = ShooterStats(
    equipment: Equipment(
      hull: Hull(
        name: "Ship",
        maxHealth: 12,
      ),
      weapons: @[
        ShooterWeaponInfo(
          name: "Gun",
          ammoCost: 1,
          damage: 1,
          attackSpeed: 3.0,
          numBullets: 1,
          bulletSpeed: 800.0,
          kind: straight,
          totalSpacing: 15.0,
        ),
        ShooterWeaponInfo(
          name: "Spread",
          ammoCost: 2,
          damage: 2,
          attackSpeed: 2.5,
          numBullets: 4,
          bulletSpeed: 500.0,
          kind: spread,
          totalAngle: 50.0,
        ),
        ShooterWeaponInfo(
          name: "OtherSpread",
          ammoCost: 1,
          damage: 1,
          attackSpeed: 1.6,
          numBullets: 7,
          bulletSpeed: 500.0,
          kind: spread,
          totalAngle: 60.0,
        ),
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
        ),
      ],
    ),
    maxAmmo: 100,
    gold: 0,
  )
  result.resetWeapons()

proc maxHealth*(stats: ShooterStats): int =
  stats.equipment.hull.maxHealth
