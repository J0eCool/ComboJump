import
  vec

type
  ShooterWeaponKind* = enum
    straight
    spread
    gatling
  ShooterWeaponInfo* = object
    name*: string
    ammoCost*: int
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
    t*: float
    numFired*: int

proc reset*(weapon: var ShooterWeapon) =
  weapon.cooldown = 0.0
  weapon.t = 0.0
  weapon.numFired = 0
