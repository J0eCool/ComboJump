type
  SkillInfo* = ref object
    name*: string
    target*: SkillTarget
    damage*: int
    manaCost*: int
    focusCost*: int
  SkillTarget* = enum
    single
    group
  SkillKind* = enum
    attack
    powerAttack
    cleave
    flameblast

let allSkills*: array[SkillKind, SkillInfo] = [
  attack: SkillInfo(
    name: "Attack",
    target: single,
    damage: 1,
    focusCost: -4,
  ),
  powerAttack: SkillInfo(
    name: "Power Attack",
    target: single,
    damage: 2,
    focusCost: 6,
  ),
  cleave: SkillInfo(
    name: "Cleave",
    target: group,
    damage: 1,
    focusCost: 5,
  ),
  flameblast: SkillInfo(
    name: "Flameblast",
    target: single,
    damage: 3,
    manaCost: 2,
  ),
]
