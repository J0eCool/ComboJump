type
  PotionKind* = enum
    healthPotion
    manaPotion
    focusPotion
  PotionInfo* = object
    kind*: PotionKind
    name*: string
    effect*: int
    charges*: int
    duration*: int
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
  ),
  PotionInfo(
    kind: healthPotion,
    name: "Health+",
    effect: 6,
    charges: 3,
    duration: 4,
  ),
  PotionInfo(
    kind: manaPotion,
    name: "Ins Mana+",
    effect: 5,
    charges: 3,
  ),
  PotionInfo(
    kind: focusPotion,
    name: "Ins Focus+",
    effect: 10,
    charges: 3,
  ),
]
