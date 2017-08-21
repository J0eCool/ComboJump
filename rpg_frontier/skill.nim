import sequtils

import
  rpg_frontier/[
    animation,
    percent,
    skill_kind,
    status_effect,
  ],
  rpg_frontier/battle/[
    battle_model,
    battle_entity,
  ],
  util,
  vec

type
  SkillInfo* = ref object
    name*: string
    target*: SkillTarget
    damage*: Percent
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
  result = entity.damage * skill.damage
  for effect in entity.effects:
    case effect.kind
    of damageBuff:
      result = result * Percent(100 + effect.amount)
    else:
      discard

# template makeTargetProc

let
  hitSingle: TargetProc =
    proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
      @[target]

  hitAll: TargetProc =
    proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
      allEntities

proc hitRepeated(times: int): TargetProc =
  return proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
    result = @[]
    for i in 0..<times:
      result.add target

proc hitRandom(numTargets: int): TargetProc =
  return proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
    result = @[]
    for i in 0..<numTargets:
      let e = random(allEntities)
      result.add e

proc slashVfx(pos: Vec): Vfx =
  let basePos = pos - vec(100)
  Vfx(
    pos: basePos,
    sprite: "Slash.png",
    scale: 4,
    duration: 0.2,
    update: (proc(vfx: var Vfx, t: float) =
      vfx.pos = basePos + t * vec(200)
    ),
  )

let
  basicHit: AttackAnimProc =
    proc(animation: AnimationCollection, onHit: HitCallback, damage: int,
         attacker: BattleEntity, targets: seq[BattleEntity]) =
      let target = targets[0]
      animation.queueAddVfx slashVfx(target.pos)
      animation.wait(0.1)
      animation.queueEvent do (t: float):
        for enemy in targets:
          onHit(enemy, damage)

  multiHit: AttackAnimProc =
    proc(animation: AnimationCollection, onHit: HitCallback, damage: int,
         attacker: BattleEntity, targets: seq[BattleEntity]) =
      for target in targets:
        basicHit(animation, onHit, damage, attacker, @[target])
        animation.wait(0.05)

let allSkills*: array[SkillKind, SkillInfo] = [
  attack: SkillInfo(
    name: "Attack",
    target: single,
    damage: 100.Percent,
    focusCost: -4,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
  powerAttack: SkillInfo(
    name: "Power Attack",
    target: single,
    damage: 160.Percent,
    focusCost: 4,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
  cleave: SkillInfo(
    name: "Cleave",
    target: group,
    damage: 100.Percent,
    focusCost: 5,
    toTargets: hitAll,
    attackAnim: basicHit,
  ),
  doubleHit: SkillInfo(
    name: "Double Hit",
    target: single,
    damage: 90.Percent,
    focusCost: 4,
    toTargets: hitRepeated(2),
    attackAnim: multiHit,
  ),
  bounceHit: SkillInfo(
    name: "Bounce Hit",
    target: single,
    damage: 140.Percent,
    focusCost: 6,
    toTargets:
      proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
        let rest = allEntities.filterIt(it != target)
        result = @[target] 
        if rest.len > 0:
          result.add random(rest)
    ,
    attackAnim:
      proc(animation: AnimationCollection, onHit: HitCallback, damage: int,
           attacker: BattleEntity, targets: seq[BattleEntity]) =
        basicHit(animation, onHit, damage, attacker, @[targets[0]])
        if targets.len > 1:
          basicHit(animation, onHit, damage div 2, attacker, @[targets[1]])
    ,
  ),
  bladeDance: SkillInfo(
    name: "Blade Dance",
    target: group,
    damage: 60.Percent,
    focusCost: 8,
    toTargets: hitRandom(6),
    attackAnim: multiHit,
  ),
  flameblast: SkillInfo(
    name: "Flameblast",
    target: single,
    damage: 300.Percent,
    manaCost: 2,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
]
