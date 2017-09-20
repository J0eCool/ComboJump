import sequtils

import
  rpg_frontier/[
    skill,
  ],
  rpg_frontier/battle/[
    battle_ai,
    battle_entity,
  ],
  util

proc selectEnemySkill*(enemy: BattleEntity): SkillInfo =
  let phase = enemy.ai.curPhase
  result = allSkills[random(phase.skills)]
  if phase.kind == summonPhaseKind and enemy.ai.willChangePhase:
    result = SkillInfo(
      kind: summonSkill,
      toSummon: phase.toSummon.mapIt(newEnemy(it)),
      name: "SUMMONING",
      toTargets: hitSingle,
    )

proc finishEnemyTurn*(enemy: BattleEntity) =
  enemy.ai.updateTurn()
  let phase = enemy.ai.curPhase
  enemy.texture = phase.texture
  enemy.stance = phase.stance
