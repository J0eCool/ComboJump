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
  allSkills[random(enemy.knownSkills)]

proc finishEnemyTurn*(enemy: BattleEntity) =
  enemy.ai.updateTurn()
  let phase = enemy.ai.curPhase
  enemy.texture = phase.texture
  enemy.stance = phase.stance
