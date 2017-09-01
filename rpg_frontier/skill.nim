import sequtils

import
  rpg_frontier/[
    animation,
    damage,
    element,
    percent,
    skill_id,
    status_effect,
  ],
  rpg_frontier/battle/[
    battle_entity,
  ],
  util,
  vec

type
  SkillKind* = enum
    attackSkill
    spellSkill
    effectSkill
  SkillInfo* = ref object
    case kind*: SkillKind
    of attackSkill:
      damage*: Percent
    of spellSkill:
      baseDamage*: Damage
    of effectSkill:
      discard
    name*: string
    target*: SkillTarget
    manaCost*: int
    focusCost*: int
    toTargets*: TargetProc
    attackAnim*: AttackAnimProc
  SkillTarget* = enum
    single
    group
    self
  TargetProc = proc(allEntities: seq[BattleEntity],
                    target: BattleEntity): seq[BattleEntity]
  AttackAnimProc = proc(
    animation: AnimationCollection, onHit: HitCallback, damage: Damage,
    attacker: BattleEntity, targets: seq[BattleEntity])
  HitCallback = proc(target: BattleEntity, damage: Damage)

proc baseDamageFor(skill: SkillInfo, entity: BattleEntity): Damage =
  case skill.kind
  of attackSkill:
    result = entity.baseDamage
    result.amounts = result.amounts * newElementSet(skill.damage)
  of spellSkill:
    result = skill.baseDamage
  of effectSkill:
    discard

proc damageFor*(skill: SkillInfo, entity: BattleEntity): Damage =
  result = skill.baseDamageFor(entity)
  for effect in entity.effects:
    case effect.kind
    of damageBuff:
      result.amounts = result.amounts + newElementSet(Percent(effect.amount))
    else:
      discard

template makeTargetProc(body: untyped): untyped {.dirty.} =
  (proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
    body
  )

let
  hitSingle: TargetProc = makeTargetProc:
    @[target]

  hitAll: TargetProc = makeTargetProc:
    allEntities

  hitBounce: TargetProc = makeTargetProc:
    let rest = allEntities.filterIt(it != target)
    result = @[target] 
    if rest.len > 0:
      result.add random(rest)


proc hitRepeated(times: int): TargetProc =
  makeTargetProc:
    result = @[]
    for i in 0..<times:
      result.add target

proc hitRandom(numTargets: int): TargetProc =
  makeTargetProc:
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
    proc(animation: AnimationCollection, onHit: HitCallback, damage: Damage,
         attacker: BattleEntity, targets: seq[BattleEntity]) =
      let target = targets[0]
      animation.queueAddVfx slashVfx(target.pos)
      animation.wait(0.1)
      animation.queueEvent do (t: float):
        for enemy in targets:
          onHit(enemy, damage)

  multiHit: AttackAnimProc =
    proc(animation: AnimationCollection, onHit: HitCallback, damage: Damage,
         attacker: BattleEntity, targets: seq[BattleEntity]) =
      for target in targets:
        basicHit(animation, onHit, damage, attacker, @[target])
        animation.wait(0.05)

let allSkills*: array[SkillID, SkillInfo] = [
  attack: SkillInfo(
    name: "Attack",
    kind: attackSkill,
    target: single,
    damage: 100.Percent,
    focusCost: -4,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
  powerHit: SkillInfo(
    name: "Power Hit",
    kind: attackSkill,
    target: single,
    damage: 160.Percent,
    focusCost: 4,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),
  cleave: SkillInfo(
    name: "Cleave",
    kind: attackSkill,
    target: group,
    damage: 100.Percent,
    focusCost: 5,
    toTargets: hitAll,
    attackAnim: basicHit,
  ),
  doubleHit: SkillInfo(
    name: "Double Hit",
    kind: attackSkill,
    target: single,
    damage: 90.Percent,
    focusCost: 4,
    toTargets: hitRepeated(2),
    attackAnim: multiHit,
  ),
  bounceHit: SkillInfo(
    name: "Bounce Hit",
    kind: attackSkill,
    target: single,
    damage: 140.Percent,
    focusCost: 6,
    toTargets: hitBounce,
    attackAnim:
      proc(animation: AnimationCollection, onHit: HitCallback, damage: Damage,
           attacker: BattleEntity, targets: seq[BattleEntity]) =
        basicHit(animation, onHit, damage, attacker, @[targets[0]])
        if targets.len > 1:
          let lessDamage = Damage(
            amounts: damage.amounts * newElementSet(50.Percent),
          )
          basicHit(animation, onHit, lessDamage, attacker, @[targets[1]])
    ,
  ),
  bladeDance: SkillInfo(
    name: "Blade Dance",
    kind: attackSkill,
    target: group,
    damage: 60.Percent,
    focusCost: 8,
    toTargets: hitRandom(6),
    attackAnim: multiHit,
  ),

  flameblast: SkillInfo(
    name: "Flameblast",
    kind: spellSkill,
    target: single,
    baseDamage: singleDamage(fire, 5, 60),
    manaCost: 2,
    toTargets: hitSingle,
    attackAnim: basicHit,
  ),

  buildup: SkillInfo(
    name: "Buildup",
    kind: effectSkill,
    target: self,
    manaCost: 5,
    toTargets: hitSingle,
    attackAnim:
      proc(animation: AnimationCollection, onHit: HitCallback, damage: Damage,
           attacker: BattleEntity, targets: seq[BattleEntity]) =
        animation.queueEvent do (t: float):
          targets[0].effects.add StatusEffect(
            kind: damageBuff,
            amount: 75,
            duration: 3,
          )
    ,
  ),
]
