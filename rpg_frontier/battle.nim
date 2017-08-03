import
  rpg_frontier/[
    transition,
  ],
  color,
  menu,
  util,
  vec

type
  BattleData* = ref object of RootObj
    player: BattleEntity
    enemy: BattleEntity
    xp: int
    isEnemyTurn: bool
  BattleEntity* = object
    name: string
    health, maxHealth: int
    mana, maxMana: int
    focus, maxFocus: int
    texture: string
    offset: Vec
  BattleController* = ref object of Controller
    battle: BattleData
    floatingTexts: seq[FloatingText]
    eventQueue: seq[BattleEvent]
    didKill: bool
    bufferClose: bool
  FloatingText* = object
    text*: string
    startPos*: Vec
    t: float
  BattleEvent* = object
    duration*: float
    update*: EventUpdate
    t: float
  EventUpdate = proc(pct: float)
  SkillInfo = object
    name: string
    damage: int
    manaCost: int
    focusCost: int


type
  EnemyKind = enum
    slime
    goblin
    ogre
  EnemyInfo = object
    kind: EnemyKind
    name: string
    health: int
    texture: string

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

proc initializeEnemyData(): seq[EnemyInfo] =
  result = @[]
  for tup in @[
    (slime, "Slime", 3, "Slime.png"),
    (goblin, "Goblin", 4, "Goblin.png"),
    (ogre, "Ogre", 5, "Ogre.png"),
  ]:
    result.add EnemyInfo(
      kind: tup[0],
      name: tup[1],
      health: tup[2],
      texture: tup[3],
    )
const enemyData = initializeEnemyData()

proc newEnemy(): BattleEntity =
  let
    enemy = random(enemyData)
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

proc newBattleData*(): BattleData =
  BattleData(
    player: newPlayer(),
    enemy: newEnemy(),
    xp: 0,
  )

proc newBattleController(battle: BattleData): BattleController =
  BattleController(
    name: "Battle",
    battle: battle,
    floatingTexts: @[],
    eventQueue: @[],
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

proc battleEntityStatusNode(entity: BattleEntity, pos: Vec, isPlayer = true): Node =
  let barSize = vec(240, 30)
  result = Node(
    pos: pos,
    children: @[
      SpriteNode(
        pos: entity.offset,
        textureName: entity.texture,
        scale: 4.0,
      ),
      BorderedTextNode(
        text: entity.name,
        pos: vec(0, -215),
      ),
      quantityBarNode(
        entity.health,
        entity.maxHealth,
        vec(0, -185),
        barSize,
        red,
        showText = isPlayer,
      ),
    ],
  )
  if isPlayer:
    result.children &= @[
      quantityBarNode(
        entity.mana,
        entity.maxMana,
        vec(0, -150),
        barSize,
        blue,
      ),
      quantityBarNode(
        entity.focus,
        entity.maxFocus,
        vec(0, -115),
        barSize,
        yellow,
      ),
    ]

proc updateAttackAnimation(controller: BattleController, pct: float) =
  if not controller.battle.isEnemyTurn:
    controller.battle.player.offset = vec(attackAnimDist * pct, 0.0)
  else:
    controller.battle.enemy.offset = vec(-attackAnimDist * pct, 0.0)

proc takeDamage(entity: var BattleEntity, damage: int): bool =
  entity.health -= damage
  return entity.health <= 0

proc processAttackDamage(controller: BattleController, damage: int) =
  var basePos: Vec
  if not controller.battle.isEnemyTurn:
    basePos = vec(300, 0)
    controller.didKill = controller.battle.enemy.takeDamage(damage)
  else:
    basePos = vec(0, 0)
    controller.didKill = controller.battle.player.takeDamage(damage)
  controller.floatingTexts.add FloatingText(
    text: $damage,
    startPos: basePos + randomVec(30.0),
  )

proc newEvent(duration: float, update: EventUpdate): BattleEvent =
  BattleEvent(
    duration: duration,
    update: update,
  )
proc newEvent(update: EventUpdate): BattleEvent =
  newEvent(0.0, update)

proc killEnemy(controller: BattleController) =
  let xp = 1
  controller.floatingTexts.add FloatingText(
    text: "+" & $xp & "xp",
    startPos: vec(350, -50) + randomVec(5.0),
  )
  controller.battle.xp += xp
  let dx = random(300.0, 700.0)
  controller.eventQueue &= @[
    newEvent(0.8) do (pct: float):
      controller.battle.enemy.offset = vec(dx * pct, -2200.0 * pct * (0.25 - pct)),
    newEvent do (pct: float):
      controller.battle.enemy.offset = vec()
      controller.battle.enemy = newEnemy(),
  ]

proc killPlayer(controller: BattleController) =
  controller.battle.player = newPlayer()
  controller.battle.enemy = newEnemy()

proc updateMaybeKill(controller: BattleController) =
  let didKill = controller.didKill
  if not didKill:
    return

  controller.didKill = false
  if not controller.battle.isEnemyTurn:
    controller.killEnemy()
  else:
    controller.killPlayer()

proc noAnimationPlaying(controller: BattleController): bool =
  controller.eventQueue.len == 0

proc isClickReady(controller: BattleController): bool =
  controller.noAnimationPlaying and not controller.battle.isEnemyTurn

proc startAttack(controller: BattleController, damage: int) =
  controller.eventQueue = @[
    newEvent(0.2) do (pct: float):
      controller.updateAttackAnimation(pct),
    newEvent do (pct: float):
      controller.processAttackDamage(damage),
    newEvent(0.2) do (pct: float):
      controller.updateAttackAnimation(1.0 - pct),
    newEvent do (pct: float):
      controller.updateMaybeKill()
      controller.battle.isEnemyTurn = not controller.battle.isEnemyTurn,
  ]

proc pos(text: FloatingText): Vec =
  text.startPos - vec(0.0, textFloatHeight * text.t / textFloatTime)

proc canAfford(battle: BattleData, attack: SkillInfo): bool =
  battle.player.mana >= attack.manaCost and
    battle.player.focus >= attack.focusCost

proc tryUseAttack(controller: BattleController, attack: SkillInfo) =
  let battle = controller.battle
  if battle.canAfford(attack) and
     controller.isClickReady:
    battle.player.mana -= attack.manaCost
    battle.player.focus -= attack.focusCost
    controller.startAttack(attack.damage)

proc attackButtonNode(controller: BattleController, attack: SkillInfo): Node =
  let
    disabled = not controller.battle.canAfford(attack)
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
          controller.tryUseAttack(attack)
  Button(
    size: vec(60, 60),
    label: attack.name,
    color: color,
    onClick: onClick,
  )

let allSkills = @[
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

proc battleView(battle: BattleData, controller: BattleController): Node {.procvar.} =
  var floaties: seq[Node] = @[]
  for text in controller.floatingTexts:
    floaties.add BorderedTextNode(
      text: text.text,
      pos: text.pos,
    )
  Node(
    pos: vec(400, 400),
    children: @[
      Button(
        pos: vec(-345, 350),
        size: vec(60, 60),
        label: "Exit",
        onClick: (proc() =
          controller.bufferClose = true
        ),
      ),
      battleEntityStatusNode(
        battle.player,
        vec(0, 0),
        isPlayer = true,
      ),
      BorderedTextNode(
        text: "XP: " & $battle.xp,
        pos: vec(0, 150),
      ),
      battleEntityStatusNode(
        battle.enemy,
        vec(300, 0),
        isPlayer = false,
      ),
      List[SkillInfo](
        pos: vec(-75, 210),
        spacing: vec(5),
        horizontal: true,
        items: allSkills,
        listNodes: (proc(skill: SkillInfo): Node =
          controller.attackButtonNode(skill)
        ),
      ),
      Button( # Debug instant-kill node
        pos: vec(450, 210),
        size: vec(60, 60),
        label: "(kill)",
        onClick: (proc() =
          controller.killEnemy()
        ),
      ),
    ] & floaties,
  )

proc clampResources(entity: var BattleEntity) =
  entity.health = entity.health.clamp(0, entity.maxHealth)
  entity.mana = entity.mana.clamp(0, entity.maxMana)
  entity.focus = entity.focus.clamp(0, entity.maxFocus)
proc clampResources(battle: BattleData) =
  battle.player.clampResources()
  battle.enemy.clampResources()

method update*(controller: BattleController, dt: float) =
  # Update floating text
  var newFloaties: seq[FloatingText] = @[]
  for text in controller.floatingTexts.mitems:
    text.t += dt
    if text.t <= textFloatTime:
      newFloaties.add text
  controller.floatingTexts = newFloaties

  # Process events
  if controller.eventQueue.len > 0:
    controller.eventQueue[0].t += dt
    let cur = controller.eventQueue[0]
    if cur.t > cur.duration:
      controller.eventQueue.delete(0)
    cur.update(cur.percent)

  if controller.noAnimationPlaying() and controller.battle.isEnemyTurn:
    controller.startAttack(1)

  controller.battle.clampResources()

  if controller.bufferClose:
    controller.shouldPop = true
    controller.bufferClose = false

method pushMenus(controller: BattleController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]

proc newBattleMenu*(battle: BattleData): Menu[BattleData, BattleController] =
  Menu[BattleData, BattleController](
    model: battle,
    view: battleView,
    controller: newBattleController(battle),
  )
