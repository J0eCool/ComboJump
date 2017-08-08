type
  SkillInfo* = object
    name*: string
    damage*: int
    manaCost*: int
    focusCost*: int

const allSkills* = @[
  SkillInfo(
    name: "Atk",
    damage: 1,
    focusCost: -5,
  ),
  SkillInfo(
    name: "Pow",
    damage: 2,
    manaCost: 2,
  ),
  SkillInfo(
    name: "Qrz",
    damage: 3,
    focusCost: 15,
  ),
]
