import
  rpg_frontier/[
    battle_entity,
    skill_kind,
  ]

type
  SkillInfo* = ref object
    name*: string
    target*: SkillTarget
    damage*: int
    manaCost*: int
    focusCost*: int
    toTargets*: TargetProc
  SkillTarget* = enum
    single
    group
  TargetProc = proc(allEntities: seq[BattleEntity],
                    target: BattleEntity): seq[BattleEntity]

let
  hitSingle =
    proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
      @[target]
  hitAll =
    proc(allEntities: seq[BattleEntity], target: BattleEntity): seq[BattleEntity] =
      allEntities

let allSkills*: array[SkillKind, SkillInfo] = [
  attack: SkillInfo(
    name: "Attack",
    target: single,
    damage: 1,
    focusCost: -4,
    toTargets: hitSingle,
  ),
  powerAttack: SkillInfo(
    name: "Power Attack",
    target: single,
    damage: 2,
    focusCost: 6,
    toTargets: hitSingle,
  ),
  cleave: SkillInfo(
    name: "Cleave",
    target: group,
    damage: 1,
    focusCost: 5,
    toTargets: hitAll,
  ),
  flameblast: SkillInfo(
    name: "Flameblast",
    target: single,
    damage: 3,
    manaCost: 2,
    toTargets: hitSingle,
  ),
]
