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

proc reset*(weapon: var ShooterWeapon) =
  weapon.cooldown = 0.0
  weapon.reload = 0.0
  weapon.ammo = weapon.info.maxAmmo

proc isReloading*(weapon: ShooterWeapon): bool =
  weapon.ammo <= 0 and weapon.info.maxAmmo > 0
