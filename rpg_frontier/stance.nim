import
  rpg_frontier/[
    status_effect,
  ]

type
  Stance* = enum
    normalStance
    powerStance
    defensiveStance
    regenStance

proc effects*(stance: Stance): seq[StatusEffect] =
  case stance
  of normalStance:
    @[]
  of powerStance:
    @[
      StatusEffect(kind: damageBuff, amount: 50),
      StatusEffect(kind: damageTakenDebuff, amount: 50),
    ]
  of defensiveStance:
    @[
      StatusEffect(kind: damageBuff, amount: -50),
      StatusEffect(kind: damageTakenDebuff, amount: -50),
    ]
  of regenStance:
    @[
      StatusEffect(kind: damageBuff, amount: -100),
      StatusEffect(kind: healthRegen, amount: 5),
    ]
