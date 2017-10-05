type
  ShooterWeaponInfo* = object
    name*: string
    attackSpeed*: float
    damage*: int
    numBullets*: int
    maxAmmo*: int
    reloadTime*: float
  ShooterWeapon* = ref object
    info*: ShooterWeaponInfo
    cooldown*: float
    reload*: float
    ammo*: int
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
  weapon.reload = 0.0
  weapon.ammo = weapon.info.maxAmmo

proc isReloading*(weapon: ShooterWeapon): bool =
  weapon.ammo <= 0 and weapon.info.maxAmmo > 0

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
        maxAmmo: 12,
        reloadTime: 1.25,
    )),
    qWeapon: ShooterWeapon(info:
      ShooterWeaponInfo(
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
