import sequtils

import
  rpg_frontier/[
    enemy,
    level,
    player_stats,
    potion,
    skill,
    skill_kind,
    transition,
  ],
  rpg_frontier/battle/[
    battle_controller,
    battle_entity,
    battle_model,
  ],
  color,
  menu,
  util,
  vec

proc skillButtonTooltipNode(skill: SkillInfo, player: BattleEntity): Node =
  var lines: seq[string] = @[]
  lines.add($skill.damageFor(player) & " Damage")
  if skill.manaCost > 0:
    lines.add($skill.manaCost & " Mana")
  if skill.focusCost > 0:
    lines.add($skill.focusCost & " Focus")
  if skill.focusCost < 0:
    lines.add("Generates " & $(-skill.focusCost) & " Focus")
  let height = 20 * lines.len + 10
  SpriteNode(
    pos: vec(0.0, -height/2 - 32.0),
    size: vec(240, height),
    color: darkGray,
    children: @[stringListNode(
      lines,
      pos = vec(0, -10 * lines.len),
      fontSize = 18,
    )]
  )

proc skillButtonNode(battle: BattleData, controller: BattleController, skill: SkillInfo): Node =
  let
    disabled = not battle.canAfford(skill) or not battle.isClickReady(controller)
    selected = battle.selectedSkill == skill
    color =
      if disabled:
        gray
      elif selected:
        lightGreen
      else:
        lightGray
    onClick =
      if disabled:
        nil
      else:
        proc() =
          battle.selectedSkill = skill
  Button(
    size: vec(180, 40),
    label: skill.name,
    color: color,
    onClick: onClick,
    hoverNode: skillButtonTooltipNode(skill, battle.player),
  )

proc quantityBarNode(cur, max: int, pos, size: Vec, color: Color, showText = true): Node =
  let
    border = 2.0
    borderedSize = size - vec(2.0 * border)
    percent = cur / max
    label =
      if showText:
        BorderedTextNode(text: $cur & " / " & $max)
      else:
        Node()
  SpriteNode(
    pos: pos,
    size: size,
    children: @[
      SpriteNode(
        pos: borderedSize * vec(percent / 2 - 0.5, 0.0),
        size: borderedSize * vec(percent, 1.0),
        color: color,
      ),
      label,
    ],
  )

proc battleEntityNode(battle: BattleData, controller: BattleController,
                      entity: BattleEntity, pos = vec()): Node =
  SpriteNode(
    pos: pos + entity.offset,
    textureName: entity.texture,
    scale: 4.0,
    children: @[
      Button(
        size: vec(100),
        invisible: true,
        onClick: (proc() =
          if entity != battle.player and battle.selectedSkill != nil:
            battle.tryUseAttack(controller, entity)
        ),
      ).Node,
    ],
  )

proc enemyEntityNode(battle: BattleData, controller: BattleController,
                     entity: BattleEntity): Node =
  let barSize = vec(180, 22)
  result = Node(
    pos: entity.pos,
    children: @[
      battleEntityNode(battle, controller, entity),
      quantityBarNode(
        entity.health,
        entity.maxHealth,
        vec(0, -60),
        barSize,
        red,
        showText = false,
      ),
      BorderedTextNode(
        text: entity.name,
        pos: vec(0, -60),
        fontSize: 18,
      ),
    ],
  )

proc playerStatusHudNode(entity: BattleEntity, pos: Vec): Node =
  let
    barSize = vec(320, 30)
    spacing = 5.0 + barSize.y
  Node(
    pos: pos,
    children: @[
      BorderedTextNode(text: entity.name),
      quantityBarNode(
        entity.health,
        entity.maxHealth,
        vec(0.0, spacing),
        barSize,
        red,
      ),
      quantityBarNode(
        entity.mana,
        entity.maxMana,
        vec(0.0, 2 * spacing),
        barSize,
        blue,
      ),
      quantityBarNode(
        entity.focus,
        entity.maxFocus,
        vec(0.0, 3 * spacing),
        barSize,
        yellow,
      ),
    ],
  )

proc potionButtonNode(battle: BattleData, controller: BattleController, potion: ptr Potion): Node =
  let
    disabled = not potion[].canUse() or not battle.isClickReady(controller)
    color =
      if disabled:
        gray
      else:
        lightGray
    onClick =
      if disabled:
        nil
      else:
        proc() =
          battle.tryUsePotion(controller, potion)
  Button(
    size: vec(180, 40),
    label: potion.info.name & " " & $potion.charges & "/" & $potion.info.charges,
    color: color,
    onClick: onClick,
  )

proc actionButtonsNode(battle: BattleData, controller: BattleController, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      List[SkillKind](
        pos: vec(0, 0),
        spacing: vec(5),
        items: battle.player.knownSkills,
        listNodes: (proc(skill: SkillKind): Node =
          battle.skillButtonNode(controller, allSkills[skill])
        ),
      ),
      List[Potion](
        pos: vec(200, 0),
        spacing: vec(5),
        items: battle.potions,
        listNodesIdx: (proc(potion: Potion, idx: int): Node =
          battle.potionButtonNode(controller, addr battle.potions[idx])
        ),
      ),
    ],
  )

proc turnQueueNode(battle: BattleData, pos: Vec): Node =
  let
    width = 400.0
    thickness = 10.0
    endHeight = 40.0
    color = lightGray
  Node(
    pos: pos,
    children: @[
      SpriteNode(
        size: vec(width, thickness),
        color: color,
      ),
      SpriteNode(
        pos: vec(-width / 2.0, 0.0),
        size: vec(thickness, endHeight),
        color: color,
      ),
      SpriteNode(
        pos: vec(width / 2.0, 0.0),
        size: vec(thickness, endHeight),
        color: color,
      ),
      List[TurnPair](
        items: battle.turnQueue,
        ignoreSpacing: true,
        listNodes: (proc(pair: TurnPair): Node =
          SpriteNode(
            pos: vec(pair.t.lerp(-0.5, 0.5) * width, 0.0),
            textureName: pair.entity.texture,
            scale: 3.0,
          )
        ),
      ),
    ],
  )

proc battleView(battle: BattleData, controller: BattleController): Node {.procvar.} =
  var extraNodes: seq[Node] = @[]
  for text in controller.floatingTexts:
    extraNodes.add BorderedTextNode(
      text: text.text,
      pos: text.pos,
    )
  for vfx in controller.vfxs:
    extraNodes.add SpriteNode(
      pos: vfx.pos,
      textureName: vfx.sprite,
      scale: vfx.scale,
    )
  Node(
    children: @[
      Button(
        pos: vec(50, 50),
        size: vec(60, 60),
        label: "Exit",
        onClick: (proc() =
          controller.bufferClose = true
        ),
      ),
      battleEntityNode(battle, controller, battle.player, battle.player.pos),
      List[BattleEntity](
        ignoreSpacing: true,
        items: battle.enemies,
        listNodes: (proc(enemy: BattleEntity): Node =
          enemyEntityNode(battle, controller, enemy)
        ),
      ),
      BorderedTextNode(
        text: battle.levelName,
        pos: vec(150, 50),
      ),
      BorderedTextNode(
        text: "Stage: " & $(battle.curStageIndex + 1) & " / " & $battle.stages.len,
        pos: vec(150, 80),
        fontSize: 18,
      ),
      BorderedTextNode(
        text: "XP: " & $battle.stats.xp,
        pos: vec(300, 70),
      ),
      playerStatusHudNode(battle.player, vec(300, 620)),
      actionButtonsNode(battle, controller, vec(610, 600)),
      turnQueueNode(battle, vec(800, 60)),
    ] & extraNodes,
  )

proc newBattleMenu*(battle: BattleData): Menu[BattleData, BattleController] =
  Menu[BattleData, BattleController](
    model: battle,
    view: battleView,
    update: battleUpdate,
    controller: newBattleController(),
  )
