type
  RewardKind* = enum
    rewardXp
  Reward* = object
    case kind*: RewardKind
    of rewardXp:
      amount*: int
