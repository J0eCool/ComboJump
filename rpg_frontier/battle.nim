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
  BattleData* = ref object of RootObj
    player: BattleEntity
    enemies: seq[BattleEntity]
    stats: PlayerStats
    turnIndex: int
    potions: seq[Potion]
    levelName: string
    stages: seq[Stage]
    curStageIndex: int
  BattleEntity* = object
    name: string
    health, maxHealth: int
    mana, maxMana: int
    focus, maxFocus: int
    texture: string
    offset: Vec
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
    health: health,
    maxHealth: health,
    mana: mana,
    maxMana: mana,
    focus: 0,
    maxFocus: focus,
    texture: "Wizard2.png",
  )

proc newEnemy(kind: EnemyKind): BattleEntity =
  let
    enemy = enemyData[kind]
    mana = 5
    focus = 10
  BattleEntity(
    name: enemy.name,
    health: enemy.health,
    maxHealth: enemy.health,
    mana: mana,
    maxMana: mana,
    focus: 0,
    maxFocus: focus,
    texture: enemy.texture,
  )

proc initPotions(): seq[Potion] =
  result = @[]
  for info in allPotionInfos:
    result.add Potion(
      info: info,
      charges: info.charges,
    )

proc spawnCurrentStage(battle: BattleData): seq[BattleEntity] =
  let
    index = battle.curStageIndex.clamp(0, battle.stages.len - 1)
    stage = battle.stages[index]
  result = @[]
  for enemyKind in stage:
    result.add newEnemy(enemyKind)

proc newBattleData*(stats: PlayerStats, level: Level): BattleData =
  result = BattleData(
    stats: stats,
    player: newPlayer(),
    potions: initPotions(),
    levelName: level.name,
    stages: level.stages,
    curStageIndex: 0,
  )
  result.enemies = result.spawnCurrentStage()
  result.turnIndex = result.enemies.len

proc newBattleController(): BattleController =
  BattleController(
    name: "Battle",
    floatingTexts: @[],
    eventQueue: @[],
    asyncQueue: @[],
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

proc battleEntityNode(entity: BattleEntity, pos = vec()): Node =
  SpriteNode(
    pos: pos + entity.offset,
    textureName: entity.texture,
    scale: 4.0,
  )

proc enemyEntityNode(entity: BattleEntity, pos: Vec): Node =
  let barSize = vec(180, 22)
  result = Node(
    pos: pos,
    children: @[
      battleEntityNode(entity),
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

proc isEnemyTurn(battle: BattleData): bool =
  battle.turnIndex < battle.enemies.len

proc updateAttackAnimation(battle: BattleData, pct: float) =
  if not battle.isEnemyTurn:
    battle.player.offset = vec(attackAnimDist * pct, 0.0)
  else:
    battle.enemies[battle.turnIndex].offset = vec(-attackAnimDist * pct, 0.0)

proc takeDamage(entity: var BattleEntity, damage: int): bool =
  entity.health -= damage
  return entity.health <= 0

proc processAttackDamage(battle: BattleData, controller: BattleController, damage: int) =
  var basePos: Vec
  if not battle.isEnemyTurn:
    basePos = vec(700, 400)
    controller.didKill = battle.enemies[0].takeDamage(damage)
  else:
    basePos = vec(400, 400)
    controller.didKill = battle.player.takeDamage(damage)
  controller.floatingTexts.add FloatingText(
    text: $damage,
    startPos: basePos + randomVec(30.0),
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
    battle.enemies = battle.spawnCurrentStage()

proc killEnemy(battle: BattleData, controller: BattleController) =
  let xpGained = 1
  controller.floatingTexts.add FloatingText(
    text: "+" & $xpGained & "xp",
    startPos: vec(750, 350) + randomVec(5.0),
  )
  battle.stats.addXp(xpGained)
  let dx = random(300.0, 700.0)
  controller.queueEvent(0.8) do (pct: float):
    battle.enemies[0].offset = vec(dx * pct, -2200.0 * pct * (0.25 - pct))
  controller.wait(0.1)
  controller.queueEvent do (pct: float):
    battle.enemies.delete(0)
    if battle.enemies.len == 0:
      battle.advanceStage(controller)
  controller.wait(0.3)

proc killPlayer(battle: BattleData, controller: BattleController) =
  controller.bufferClose = true

proc updateMaybeKill(battle: BattleData, controller: BattleController) =
  let didKill = controller.didKill
  if not didKill:
    return

  controller.didKill = false
  if not battle.isEnemyTurn:
    battle.killEnemy(controller)
  else:
    battle.killPlayer(controller)

proc noAnimationPlaying(controller: BattleController): bool =
  controller.eventQueue.len == 0

proc isClickReady(battle: BattleData, controller: BattleController): bool =
  controller.noAnimationPlaying and not battle.isEnemyTurn

proc startAttack(battle: BattleData, controller: BattleController, damage: int) =
  controller.queueEvent(0.1) do (t: float):
    battle.updateAttackAnimation(t)
  controller.queueEvent do (t: float):
    battle.processAttackDamage(controller, damage)
    controller.queueAsync(0.175) do (t: float):
      battle.updateAttackAnimation(1.0 - t)
  controller.queueEvent do (t: float):
    battle.updateMaybeKill(controller)
  controller.wait(0.25)
  controller.queueEvent do (t: float):
    if battle.isEnemyTurn:
      battle.turnIndex += 1
    else:
      battle.turnIndex = 0

proc pos(text: FloatingText): Vec =
  text.startPos - vec(0.0, textFloatHeight * text.t / textFloatTime)

proc canAfford(battle: BattleData, attack: SkillInfo): bool =
  battle.player.mana >= attack.manaCost and
    battle.player.focus >= attack.focusCost

proc tryUseAttack(battle: BattleData, controller: BattleController, attack: SkillInfo) =
  if battle.canAfford(attack) and
     battle.isClickReady(controller):
    battle.player.mana -= attack.manaCost
    battle.player.focus -= attack.focusCost
    battle.startAttack(controller, attack.damage)

proc attackButtonTooltipNode(attack: SkillInfo): Node =
  var lines: seq[string] = @[]
  lines.add($attack.damage & " Damage")
  if attack.manaCost > 0:
    lines.add($attack.manaCost & " Mana")
  if attack.focusCost > 0:
    lines.add($attack.focusCost & " Focus")
  if attack.focusCost < 0:
    lines.add("Generates " & $(-attack.focusCost) & " Focus")
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

proc attackButtonNode(battle: BattleData, controller: BattleController, attack: SkillInfo): Node =
  let
    disabled = not battle.canAfford(attack) or not battle.isClickReady(controller)
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
          battle.tryUseAttack(controller, attack)
  Button(
    size: vec(180, 40),
    label: attack.name,
    color: color,
    onClick: onClick,
    hoverNode: attackButtonTooltipNode(attack),
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
      List[SkillInfo](
        pos: vec(0, 0),
        spacing: vec(5),
        items: allSkills,
        listNodes: (proc(skill: SkillInfo): Node =
          battle.attackButtonNode(controller, skill)
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
      battleEntityNode(battle.player, vec(130, 400)),
      List[BattleEntity](
        pos: vec(700, 200),
        spacing: vec(130),
        items: battle.enemies,
        listNodes: (proc(enemy: BattleEntity): Node =
          enemyEntityNode(enemy, vec(0, 0)),
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
    ] & floaties,
  )

proc clampResources(entity: var BattleEntity) =
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

  if controller.noAnimationPlaying() and battle.isEnemyTurn:
    battle.startAttack(controller, 1)

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
