import
  spells/runes

type
  RewardKind* = enum
    rewardXp
    rewardRune

  Reward* = object
    case kind*: RewardKind
    of rewardXp:
      amount*: int
    of rewardRune:
      rune*: Rune
