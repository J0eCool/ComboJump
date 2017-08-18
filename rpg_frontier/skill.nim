import
  rpg_frontier/[
    animation,
    skill_kind,
  ],
  rpg_frontier/battle/[
    battle_model,
    battle_entity,
  ],
  vec

type
  SkillInfo* = ref object
    name*: string
    target*: SkillTarget
    damage*: int
    manaCost*: int
    focusCost*: int
    toTargets*: TargetProc
    attackAnim*: AttackAnimProc
  SkillTarget* = enum
    single
    group
  TargetProc = proc(allEntities: seq[BattleEntity],
                    target: BattleEntity): seq[BattleEntity]
  AttackAnimProc = proc(animation: AnimationCollection, onHit: HitCallback, damage: int,
                        attacker: BattleEntity, targets: seq[BattleEntity])
  HitCallback = proc(target: BattleEntity, damage: int)

proc damageFor*(skill: SkillInfo, entity: BattleEntity): int =
  skill.damage * entity.damage

let
  hitSingle: TargetProc =
    proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
      @[target]
  hitAll: TargetProc =
    proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
      allEntities

let
  basicHit: AttackAnimProc =
    proc(animation: AnimationCollection, onHit: HitCallback, damage: int,
         attacker: BattleEntity, targets: seq[BattleEntity]) =
      let target = targets[0]
      animation.queueEvent(0.1) do (t: float):
        attacker.updateAttackAnimation(t)
      animation.queueEvent do (t: float):
        let basePos = target.pos - vec(100)
        animation.addVfx Vfx(
          pos: basePos,
          sprite: "Slash.png",
          scale: 4,
          duration: 0.2,
          update: (proc(vfx: var Vfx, t: float) =
            vfx.pos = basePos + t * vec(200)
          ),
        )
      animation.wait(0.1)
      animation.queueEvent do (t: float):
        for enemy in targets:
          onHit(enemy, damage)
        animation.queueAsync(0.175) do (t: float):
          attacker.updateAttackAnimation(1.0 - t)
      animation.wait(0.25)

let allSkills*: array[SkillKind, SkillInfo] = [
  attack: SkillInfo(
    name: "Attack",
    target: single,
    damage: 1,
    focusCost: -4,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
  powerAttack: SkillInfo(
    name: "Power Attack",
    target: single,
    damage: 2,
    focusCost: 6,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
  cleave: SkillInfo(
    name: "Cleave",
    target: group,
    damage: 1,
    focusCost: 5,
    toTargets: hitAll,
    attackAnim: basicHit,
  ),
  flameblast: SkillInfo(
    name: "Flameblast",
    target: single,
    damage: 3,
    manaCost: 2,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
]
