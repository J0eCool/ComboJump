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
    name: "Hth",
    effect: 5,
    charges: 3,
  ),
  PotionInfo(
    kind: manaPotion,
    name: "Mna",
    effect: 5,
    charges: 3,
  ),
  PotionInfo(
    kind: focusPotion,
    name: "Fcs",
    effect: 10,
    charges: 3,
  ),
]
