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

proc menuString*(reward: Reward): string =
  case reward.kind
  of rewardXp:
    $reward.amount & " XP"
  of rewardRune:
    $reward.rune & " Rune"
