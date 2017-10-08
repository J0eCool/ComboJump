type
  ShooterWeaponKind* = enum
    straight
    spread
  ShooterWeaponInfo* = object
    name*: string
    maxAmmo*: int
    reloadTime*: float
    damage*: int
    attackSpeed*: float
    numBullets*: int
    bulletSpeed*: float
    case kind*: ShooterWeaponKind
    of straight:
      totalSpacing*: float
    of spread:
      totalAngle*: float
  ShooterWeapon* = ref object
    info*: ShooterWeaponInfo
    cooldown*: float
    reload*: float
    ammo*: int

proc reset*(weapon: var ShooterWeapon) =
  weapon.cooldown = 0.0
  weapon.reload = 0.0
  weapon.ammo = weapon.info.maxAmmo

proc isReloading*(weapon: ShooterWeapon): bool =
  weapon.ammo <= 0 and weapon.info.maxAmmo > 0
