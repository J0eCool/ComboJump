import sequtils

import
  rpg_frontier/[
    ailment,
    animation,
    damage,
    element,
    enemy,
    level,
    player_stats,
    potion,
    skill,
    skill_kind,
    status_effect,
    transition,
  ],
  rpg_frontier/battle/[
    battle_controller,
    battle_entity,
    battle_model,
  ],
  color,
  input,
  menu,
  util,
  vec

let
  skillHotkeys = @[keyQ, keyW, keyE, keyR, keyT]
  potionHotkeys = @[n1, n2, n3, n4, n5]

proc skillButtonTooltipNode(skill: SkillInfo, player: BattleEntity): Node =
  var lines: seq[string] = @[]
  lines.add($skill.damageFor(player).total() & " Damage")
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

proc skillButtonNode(battle: BattleData, controller: BattleController,
                     skill: SkillInfo, index: int): Node =
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
    hotkey =
      if index >= 0 and index < skillHotkeys.len:
        skillHotkeys[index]
      else:
        none
  Button(
    size: vec(180, 40),
    label: skill.name,
    color: color,
    onClick: onClick,
    hoverNode: skillButtonTooltipNode(skill, battle.player),
    hotkey: hotkey,
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

proc statusEffectNode(effect: StatusEffect): Node {.procvar.} =
  Button(
    size: vec(40),
    label: ($effect.kind)[0..0] & $effect.duration,
  )

proc entityStatusNode(entity: BattleEntity, pos: Vec): Node =
  List[StatusEffect](
    pos: pos,
    items: entity.effects,
    listNodes: statusEffectNode,
    horizontal: true,
    spacing: vec(5),
  )

proc ailmentsNode(ailments: Ailments, pos: Vec): Node =
  var elements: seq[Element] = @[]
  for e in Element:
    if ailments.stacks(e) > 0 or ailments.progress(e) > 0:
      elements.add e
  List[Element](
    pos: pos,
    items: elements,
    listNodes: (proc(element: Element): Node =
      let state = ailments[element]
      nodes(@[
        quantityBarNode(
          state.progress,
          state.capacity,
          vec(),
          vec(120, 22),
          ailmentColor(element),
          showText = false,
        ),
        BorderedTextNode(
          text: ailmentName(element) & " - " & $state.stacks,
          fontSize: 16,
        ),
      ])
    ),
    spacing: vec(0, 28),
  )

proc battleEntityNode(battle: BattleData, controller: BattleController,
                      entity: BattleEntity, pos = vec()): Node =
  SpriteNode(
    pos: pos + entity.offset,
    textureName: entity.texture,
    scale: 4.0,
  )

proc enemyEntityNode(battle: BattleData, controller: BattleController,
                     entity: BattleEntity): Node =
  let barSize = vec(180, 22)
  result = Node(
    pos: entity.pos,
    children: @[
      battleEntityNode(battle, controller, entity),
      entityStatusNode(entity, vec(80, 80)),
      quantityBarNode(
        entity.health,
        entity.maxHealth,
        vec(0, -60),
        barSize,
        red,
        showText = false,
      ),
      ailmentsNode(entity.ailments, vec(100, -30)),
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

proc potionButtonNode(battle: BattleData, controller: BattleController,
                      potion: ptr Potion, index: int): Node =
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
    hotkey =
      if index >= 0 and index < potionHotkeys.len:
        potionHotkeys[index]
      else:
        none
  Button(
    size: vec(180, 40),
    label: potion.info.name & " " & $potion.charges & "/" & $potion.info.charges,
    color: color,
    onClick: onClick,
    hotkey: hotkey,
  )

proc actionButtonsNode(battle: BattleData, controller: BattleController, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      List[SkillKind](
        pos: vec(0, 0),
        spacing: vec(5),
        items: battle.player.knownSkills,
        listNodesIdx: (proc(skill: SkillKind, idx: int): Node =
          battle.skillButtonNode(controller, allSkills[skill], idx)
        ),
      ),
      List[Potion](
        pos: vec(200, 0),
        spacing: vec(5),
        items: battle.potions,
        listNodesIdx: (proc(potion: Potion, idx: int): Node =
          battle.potionButtonNode(controller, addr battle.potions[idx], idx)
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

let targetColor = rgb(112, 224, 182)
proc entityTargetNode(battle: BattleData, controller: BattleController, entity: BattleEntity): Node =
  Button(
    size: vec(100),
    pos: entity.pos,
    color: targetColor,
    onClick: (proc() =
      battle.tryUseAttack(controller, entity)
    ),
  )

proc attackTargetsNode(battle: BattleData, controller: BattleController): Node =
  if not battle.isClickReady(controller) or battle.selectedSkill == nil:
    return Node()
  case battle.selectedSkill.target
  of single:
    List[BattleEntity](
      ignoreSpacing: true,
      items: battle.enemies,
      listNodes: (proc(enemy: BattleEntity): Node =
        entityTargetNode(battle, controller, enemy)
      ),
    )
  of self:
    entityTargetNode(battle, controller, battle.player)
  of group:
    Button(
      size: vec(400),
      pos: vec(800, 400),
      color: targetColor,
      onClick: (proc() =
        battle.tryUseAttack(controller, nil)
      ),
    )

proc battleView(battle: BattleData, controller: BattleController): Node {.procvar.} =
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
      attackTargetsNode(battle, controller),
      battleEntityNode(battle, controller, battle.player, battle.player.pos),
      entityStatusNode(battle.player, battle.player.pos + vec(-80, 80)),
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
    ] & controller.animation.nodes(),
  )

proc newBattleMenu*(battle: BattleData): Menu[BattleData, BattleController] =
  Menu[BattleData, BattleController](
    model: battle,
    view: battleView,
    update: battleUpdate,
    controller: newBattleController(),
  )
