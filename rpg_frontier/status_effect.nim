type
  StatusEffect* = object
    kind*: StatusEffectKind
    amount*: int
    duration*: int
  StatusEffectKind* = enum
    healthRegen
    manaRegen
