import
  quick_shoot/[
    weapon,
  ]

type
  Equipment* = object
    hull*: Hull
    weapons*: seq[ShooterWeaponInfo]

  Hull* = object
    name*: string
    maxHealth*: int
