type
  SkillInfo* = ref object
    name*: string
    damage*: int
    manaCost*: int
    focusCost*: int
  SkillKind* = enum
    attack
    powerAttack
    flameblast

let allSkills*: array[SkillKind, SkillInfo] = [
  attack: SkillInfo(
    name: "Attack",
    damage: 1,
    focusCost: -4,
  ),
  powerAttack: SkillInfo(
    name: "Power Attack",
    damage: 2,
    focusCost: 6,
  ),
  flameblast: SkillInfo(
    name: "Flameblast",
    damage: 3,
    manaCost: 2,
  ),
]
