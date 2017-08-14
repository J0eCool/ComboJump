import sequtils

import
  rpg_frontier/[
    enemy,
    level,
    player_stats,
    potion,
    skill,
    transition,
  ],
  color,
  menu,
  util,
  vec

type
  TurnPair = tuple[entity: BattleEntity, t: float]
  BattleData* = ref object of RootObj
    player: BattleEntity
    enemies: seq[BattleEntity]
    turnQueue: seq[TurnPair]
    activeEntity: BattleEntity
    selectedSkill: SkillInfo
    stats: PlayerStats
    potions: seq[Potion]
    levelName: string
    stages: seq[Stage]
    curStageIndex: int
  BattleEntity* = ref object
    name: string
    texture: string
    pos: Vec
    health, maxHealth: int
    mana, maxMana: int
    focus, maxFocus: int
    damage: int
    speed: float
    offset: Vec
    knownSkills: seq[SkillKind]
  BattleController* = ref object of Controller
    floatingTexts: seq[FloatingText]
    eventQueue: seq[BattleEvent]
    asyncQueue: seq[BattleEvent]
    didKill: bool
    bufferClose: bool
  FloatingText* = object
    text*: string
    startPos*: Vec
    t: float
  BattleEvent = object
    duration: float
    update: EventUpdate
    t: float
  EventUpdate = proc(pct: float)

proc percent(event: BattleEvent): float =
  if event.duration == 0.0:
    0.0
  else:
    clamp(event.t / event.duration, 0, 1)

const
  textFloatHeight = 160.0
  textFloatTime = 1.25
  attackAnimDist = 250.0

proc newPlayer(): BattleEntity =
  let
    health = 10
    mana = 8
    focus = 20
  BattleEntity(
    name: "Player",
    texture: "Wizard2.png",
    pos: vec(130, 400),
    health: health,
    maxHealth: health,
    mana: mana,
    maxMana: mana,
    focus: 0,
    maxFocus: focus,
    speed: 1.0,
    knownSkills: @[
      attack,
      powerAttack,
    ],
  )

proc newEnemy(kind: EnemyKind): BattleEntity =
  let
    enemy = enemyData[kind]
    mana = 5
    focus = 10
  BattleEntity(
    name: enemy.name,
    texture: enemy.texture,
    health: enemy.health,
    maxHealth: enemy.health,
    mana: mana,
    maxMana: mana,
    focus: 0,
    maxFocus: focus,
    damage: enemy.damage,
    speed: enemy.speed,
    knownSkills: @[attack],
  )

proc initPotions(): seq[Potion] =
  result = @[]
  for info in allPotionInfos:
    result.add Potion(
      info: info,
      charges: info.charges,
    )

proc currentStageEnemies(battle: BattleData): seq[BattleEntity] {.nosideeffect.} =
  let
    index = battle.curStageIndex.clamp(0, battle.stages.len - 1)
    stage = battle.stages[index]
  result = @[]
  for enemyKind in stage:
    let enemy = newEnemy(enemyKind)
    enemy.pos = vec(630, 240) + vec(100, 150) * result.len
    result.add enemy

proc freshTurnOrder(battle: BattleData): seq[TurnPair] =
  result = @[]
  result.add((battle.player, random(0.0, 1.0)))
  for enemy in battle.enemies:
    result.add((enemy, random(0.0, 1.0)))

proc spawnCurrentStage(battle: BattleData) =
  battle.enemies = battle.currentStageEnemies()
  battle.turnQueue = battle.freshTurnOrder()

proc newBattleData*(stats: PlayerStats, level: Level): BattleData =
  result = BattleData(
    player: newPlayer(),
    stats: stats,
    potions: initPotions(),
    levelName: level.name,
    stages: level.stages,
    curStageIndex: 0,
  )
  result.selectedSkill = allSkills[result.player.knownSkills[0]]
  result.spawnCurrentStage()

proc newBattleController(): BattleController =
  BattleController(
    name: "Battle",
    floatingTexts: @[],
    eventQueue: @[],
    asyncQueue: @[],
  )

proc isEnemyTurn(battle: BattleData): bool =
  battle.activeEntity != nil and battle.activeEntity != battle.player

proc updateAttackAnimation(battle: BattleData, pct: float) =
  let mult =
    if not battle.isEnemyTurn:
      1.0
    else:
      -1.0
  battle.activeEntity.offset = vec(attackAnimDist * pct * mult, 0.0)

proc takeDamage(entity: BattleEntity, damage: int): bool =
  entity.health -= damage
  return entity.health <= 0

proc processAttackDamage(controller: BattleController, damage: int, target: BattleEntity) =
  controller.didKill = target.takeDamage(damage)
  controller.floatingTexts.add FloatingText(
    text: $damage,
    startPos: target.pos + randomVec(30.0),
  )

proc queueEvent(controller: BattleController, duration: float, update: EventUpdate) =
  controller.eventQueue.add BattleEvent(
    duration: duration,
    update: update,
  )
proc queueEvent(controller: BattleController, update: EventUpdate) =
  controller.queueEvent(0.0, update)
proc wait(controller: BattleController, duration: float) =
  controller.queueEvent(duration, (proc(t: float) = discard))

proc queueAsync(controller: BattleController, duration: float, update: EventUpdate) =
  controller.asyncQueue.add BattleEvent(
    duration: duration,
    update: update,
  )

proc advanceStage(battle: BattleData, controller: BattleController) =
  if battle.curStageIndex + 1 >= battle.stages.len:
    controller.bufferClose = true
  else:
    battle.curStageIndex += 1
    battle.spawnCurrentStage()

proc killEnemy(battle: BattleData, controller: BattleController, target: BattleEntity) =
  let xpGained = 1
  controller.floatingTexts.add FloatingText(
    text: "+" & $xpGained & "xp",
    startPos: vec(750, 350) + randomVec(5.0),
  )
  battle.stats.addXp(xpGained)
  let dx = random(300.0, 700.0)
  controller.queueEvent(0.8) do (pct: float):
    target.offset = vec(dx * pct, -2200.0 * pct * (0.25 - pct))
  controller.wait(0.1)
  controller.queueEvent do (pct: float):
    battle.enemies.mustRemove(target)
    battle.turnQueue = battle.turnQueue.filterIt(it.entity != target)
    if battle.enemies.len == 0:
      battle.advanceStage(controller)
  controller.wait(0.3)

proc killPlayer(battle: BattleData, controller: BattleController) =
  controller.bufferClose = true

proc updateMaybeKill(battle: BattleData, controller: BattleController, target: BattleEntity) =
  let didKill = controller.didKill
  if not didKill:
    return

  controller.didKill = false
  if target == battle.player:
    battle.killPlayer(controller)
  else:
    battle.killEnemy(controller, target)

proc noAnimationPlaying(controller: BattleController): bool =
  controller.eventQueue.len == 0

proc isClickReady(battle: BattleData, controller: BattleController): bool =
  controller.noAnimationPlaying and battle.activeEntity == battle.player

proc updateTurnQueue(battle: BattleData, dt: float) =
  if battle.activeEntity != nil:
    return
  for pair in battle.turnQueue:
    if pair.t >= 1.0:
      battle.activeEntity = pair.entity
      return
  for pair in battle.turnQueue.mitems:
    pair.t += dt * pair.entity.speed

proc endTurn(battle: BattleData) =
  for pair in battle.turnQueue.mitems:
    if pair.entity == battle.activeEntity:
      pair.t -= 1.0
      break
  battle.activeEntity = nil

proc startAttack(battle: BattleData, controller: BattleController, damage: int, target: BattleEntity) =
  controller.queueEvent(0.1) do (t: float):
    battle.updateAttackAnimation(t)
  controller.queueEvent do (t: float):
    controller.processAttackDamage(damage, target)
    controller.queueAsync(0.175) do (t: float):
      battle.updateAttackAnimation(1.0 - t)
  controller.queueEvent do (t: float):
    battle.updateMaybeKill(controller, target)
  controller.wait(0.25)
  controller.queueEvent do (t: float):
    battle.endTurn()

proc canAfford(battle: BattleData, skill: SkillInfo): bool =
  battle.player.mana >= skill.manaCost and
    battle.player.focus >= skill.focusCost

proc tryUseAttack(battle: BattleData, controller: BattleController, entity: BattleEntity) =
  let skill = battle.selectedSkill
  assert skill != nil
  assert entity != nil
  if battle.canAfford(skill) and
     battle.isClickReady(controller):
    battle.player.mana -= skill.manaCost
    battle.player.focus -= skill.focusCost
    battle.startAttack(controller, skill.damage, entity)

proc pos(text: FloatingText): Vec =
  text.startPos - vec(0.0, textFloatHeight * text.t / textFloatTime)

proc skillButtonTooltipNode(skill: SkillInfo): Node =
  var lines: seq[string] = @[]
  lines.add($skill.damage & " Damage")
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
    hoverNode: skillButtonTooltipNode(skill),
  )

proc canUse(potion: Potion): bool =
  potion.charges > 0 and potion.cooldown == 0

proc tryUsePotion(battle: BattleData, controller: BattleController, potion: ptr Potion) =
  if not potion[].canUse():
    return
  potion.charges -= 1

  let info = potion.info
  case info.kind
  of healthPotion:
    battle.player.health += info.effect
  of manaPotion:
    battle.player.mana += info.effect

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
    width = 600.0
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
            scale: 2.0,
          )
        ),
      ),
    ],
  )

proc battleView(battle: BattleData, controller: BattleController): Node {.procvar.} =
  var floaties: seq[Node] = @[]
  for text in controller.floatingTexts:
    floaties.add BorderedTextNode(
      text: text.text,
      pos: text.pos,
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
    ] & floaties,
  )

proc clampResources(entity: BattleEntity) =
  entity.health = entity.health.clamp(0, entity.maxHealth)
  entity.mana = entity.mana.clamp(0, entity.maxMana)
  entity.focus = entity.focus.clamp(0, entity.maxFocus)
proc clampResources(battle: BattleData) =
  battle.player.clampResources()
  for enemy in battle.enemies.mitems:
    enemy.clampResources()

proc updateFloatingText(controller: BattleController, dt: float) =
  var newFloaties: seq[FloatingText] = @[]
  for text in controller.floatingTexts.mitems:
    text.t += dt
    if text.t <= textFloatTime:
      newFloaties.add text
  controller.floatingTexts = newFloaties

proc updateEventQueue(controller: BattleController, dt: float) =
  if controller.eventQueue.len > 0:
    controller.eventQueue[0].t += dt
    let cur = controller.eventQueue[0]
    if cur.t > cur.duration:
      controller.eventQueue.delete(0)
    cur.update(cur.percent)

proc updateAsyncQueue(controller: BattleController, dt: float) =
  var i = controller.asyncQueue.len - 1
  while i >= 0:
    controller.asyncQueue[i].t += dt
    let cur = controller.asyncQueue[i]
    cur.update(cur.percent)
    if cur.t > cur.duration:
      controller.asyncQueue.delete(i)
    i -= 1

proc battleUpdate(battle: BattleData, controller: BattleController, dt: float) =
  if controller.bufferClose:
    controller.shouldPop = true
    controller.bufferClose = false
    return

  controller.updateFloatingText(dt)
  controller.updateEventQueue(dt)
  controller.updateAsyncQueue(dt)

  if controller.noAnimationPlaying():
    battle.updateTurnQueue(dt)
    if battle.isEnemyTurn:
      battle.startAttack(controller, battle.activeEntity.damage, battle.player)

  battle.clampResources()

method pushMenus(controller: BattleController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]

proc newBattleMenu*(battle: BattleData): Menu[BattleData, BattleController] =
  Menu[BattleData, BattleController](
    model: battle,
    view: battleView,
    update: battleUpdate,
    controller: newBattleController(),
  )
