import
  rpg_frontier/[
    stance,
  ]

type
  BattleAI* = object
    phases*: seq[BattleAIPhase]
    turns*: int
    curPhaseIdx: int

  BattleAIPhase* = object
    stance*: Stance
    texture*: string
    duration*: int

proc simpleAI*(texture: string): BattleAI =
  BattleAI(phases: @[
    BattleAIPhase(
      stance: normalStance,
      texture: texture,
    )
  ])

proc curPhase*(ai: BattleAI): BattleAIPhase =
  ai.phases[ai.curPhaseIdx]

proc updateTurn*(ai: var BattleAI) =
  ai.turns += 1
  if ai.turns >= ai.curPhase.duration:
    ai.turns = 0
    ai.curPhaseIdx = (ai.curPhaseIdx + 1) mod ai.phases.len
