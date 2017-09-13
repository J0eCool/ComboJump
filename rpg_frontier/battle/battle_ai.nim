import
  rpg_frontier/[
    skill_id,
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
    skills*: seq[SkillID]

proc simpleAI*(texture: string, skills = @[attack]): BattleAI =
  BattleAI(phases: @[
    BattleAIPhase(
      stance: normalStance,
      texture: texture,
      skills: skills,
    )
  ])

proc curPhase*(ai: BattleAI): BattleAIPhase =
  ai.phases[ai.curPhaseIdx]

proc updateTurn*(ai: var BattleAI) =
  ai.turns += 1
  if ai.turns >= ai.curPhase.duration:
    ai.turns = 0
    ai.curPhaseIdx = (ai.curPhaseIdx + 1) mod ai.phases.len
