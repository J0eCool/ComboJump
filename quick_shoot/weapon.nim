import
  vec

type
  ShooterWeaponKind* = enum
    straight
    spread
    gatling
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
    of gatling:
      numBarrels*: int
      barrelRotateSpeed*: float
      barrelOffset*: float
      barrelSize*: Vec
  ShooterWeapon* = ref object
    info*: ShooterWeaponInfo
    cooldown*: float
    reload*: float
    ammo*: int
    t*: float
    numFired*: int

proc reset*(weapon: var ShooterWeapon) =
  weapon.cooldown = 0.0
  weapon.reload = 0.0
  weapon.ammo = weapon.info.maxAmmo
  weapon.t = 0.0
  weapon.numFired = 0

proc isReloading*(weapon: ShooterWeapon): bool =
  weapon.ammo <= 0 and weapon.info.maxAmmo > 0
