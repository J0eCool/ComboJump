import
  rpg_frontier/[
    player_stats,
    skill,
    skill_id,
    transition,
  ],
  menu,
  util,
  vec


type
  SkillSelect = ref object of RootObj
    stats: PlayerStats
  SkillSelectController = ref object of Controller
    bufferClose: bool

proc newSkillSelect(stats: PlayerStats): SkillSelect =
  SkillSelect(
    stats: stats,
  )

proc newSkillSelectController(): SkillSelectController =
  SkillSelectController()

method pushMenus(controller: SkillSelectController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]
    controller.shouldPop = true
    controller.bufferClose = false

proc skillSelectView(levels: SkillSelect, controller: SkillSelectController): Node {.procvar.} =
  nodes(@[
    BorderedTextNode(
      pos: vec(600, 150),
      text: "Skill Select",
      fontSize: 32,
    ),
    Button(
      pos: vec(100, 150),
      size: vec(50, 30),
      label: "Back",
      onClick: (proc() =
        controller.bufferClose = true
      ),
    ),
    List[SkillID](
      pos: vec(200, 300),
      spacing: vec(5),
      items: allOf[SkillID](),
      listNodes: (proc(id: SkillID): Node =
        let skill = allSkills[id]
        Button(
          size: vec(200, 60),
          label: skill.name,
          onClick: (proc() =
            echo "Clicked on ", skill.name
          ),
        ),
      ),
    ),
  ])

proc newSkillSelectMenu*(stats: PlayerStats): Menu[SkillSelect, SkillSelectController] =
  Menu[SkillSelect, SkillSelectController](
    model: newSkillSelect(stats),
    view: skillSelectView,
    controller: newSkillSelectController(),
  )
