type
  PotionKind* = enum
    healthPotion
    manaPotion
    focusPotion
    damagePotion
  PotionInfo* = object
    kind*: PotionKind
    name*: string
    effect*: int
    charges*: int
    duration*: int
    instantUse*: bool
  Potion* = object
    info*: PotionInfo
    charges*: int
    cooldown*: int

const allPotionInfos* = @[
  PotionInfo(
    kind: healthPotion,
    name: "Ins Health+",
    effect: 10,
    charges: 3,
    instantUse: true,
  ),
  PotionInfo(
    kind: healthPotion,
    name: "Health+",
    effect: 5,
    charges: 3,
    duration: 4,
  ),
  PotionInfo(
    kind: focusPotion,
    name: "Focus+",
    effect: 6,
    charges: 2,
    duration: 4,
  ),
  PotionInfo(
    kind: damagePotion,
    name: "Damage+",
    effect: 50,
    charges: 2,
    duration: 4,
    instantUse: true,
  ),
]
