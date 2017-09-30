import sequtils

import
  rpg_frontier/[
    player_stats,
    skill,
    skill_id,
  ],
  color,
  input,
  menu,
  transition,
  util,
  vec


type
  SkillSelectController = ref object of Controller

proc newSkillSelectController(): SkillSelectController =
  SkillSelectController()

proc skillSelectView(stats: PlayerStats, controller: SkillSelectController): Node {.procvar.} =
  nodes(@[
    BorderedTextNode(
      pos: vec(600, 150),
      text: "Skill Select",
      fontSize: 32,
    ),
    Button(
      pos: vec(100, 150),
      size: vec(90, 60),
      label: "Back",
      onClick: (proc() =
        controller.shouldPop = true
        controller.queueMenu downcast(newFadeOnlyOut())
      ),
    ),
    List[SkillID](
      pos: vec(200, 300),
      spacing: vec(50),
      items: stats.skills,
      listNodesIdx: (proc(id: SkillID, idx: int): Node =
        let skill = allSkills[id]
        result = nodes(@[
          SpriteNode(
            pos: vec(25, 0),
            size: vec(294, 44),
            color: lightGray,
          ),
          BorderedTextNode(text: skill.name),
        ])
        if idx > 0:
          result.children.add Button(
            pos: vec(-100, 0),
            size: vec(40),
            label: "^",
            onClick: (proc() =
              swap(stats.skills[idx], stats.skills[idx - 1])
            ),
          )
        if idx < stats.skills.len - 1:
          result.children.add Button(
            pos: vec(100, 0),
            size: vec(40),
            label: "v",
            onClick: (proc() =
              swap(stats.skills[idx], stats.skills[idx + 1])
            ),
          )
        if id != attack:
          result.children.add Button(
            pos: vec(150, 0),
            size: vec(40),
            label: "x",
            onClick: (proc() =
              stats.skills.delete(idx)
            ),
          )
      ),
    ),
    List[SkillID](
      pos: vec(600, 300),
      spacing: vec(5),
      width: 3,
      items: allOf[SkillID]().filterIt(it notin stats.skills),
      listNodes: (proc(id: SkillID): Node =
        let skill = allSkills[id]
        Button(
          size: vec(160, 50),
          label: skill.name,
          onClick: (proc() =
            if stats.skills.len < 5:
              stats.skills.add id
          ),
        ),
      ),
    ),
  ])

proc newSkillSelectMenu*(stats: PlayerStats): Menu[PlayerStats, SkillSelectController] =
  Menu[PlayerStats, SkillSelectController](
    model: stats,
    view: skillSelectView,
    controller: newSkillSelectController(),
  )
