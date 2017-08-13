type
  SkillInfo* = ref object
    name*: string
    damage*: int
    manaCost*: int
    focusCost*: int

let allSkills* = @[
  SkillInfo(
    name: "Attack",
    damage: 1,
    focusCost: -4,
  ),
  SkillInfo(
    name: "Power Attack",
    damage: 2,
    focusCost: 6,
  ),
  SkillInfo(
    name: "Flameblast",
    damage: 3,
    manaCost: 2,
  ),
]
