import math, macros, times
from sdl2 import RendererPtr

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  component/collider,
  system/render,
  camera,
  color,
  drawing,
  entity,
  event,
  game,
  input,
  logging,
  menu,
  program,
  resources,
  vec,
  util

##
## TODO: put these in the right files
##

type
  Transition = ref object of RootObj
  TransitionController = ref object of Controller
    menu: MenuBase
    onlyFadeOut: bool
    t: float
    shouldPush: bool
    reverse: bool

const transitionDuration = 0.3

proc percentDone(controller: TransitionController): float =
  result = clamp(controller.t / transitionDuration, 0.0, 1.0)
  if controller.reverse:
    result = 1.0 - result

proc transitionView(transition: Transition, controller: TransitionController): Node {.procvar.} =
  let size = vec(2400, 900)
  SpriteNode(
    size: size,
    pos: vec(controller.percentDone.lerp(-0.5, 0.5) * size.x, size.y / 2),
  )

proc newTransitionMenu(menu: MenuBase): Menu[Transition, TransitionController] =
  Menu[Transition, TransitionController](
    model: Transition(),
    view: transitionView,
    controller: TransitionController(
      name: "Transition - NewMenu",
      menu: menu,
    ),
  )

proc newFadeOnlyOut(): Menu[Transition, TransitionController] =
  Menu[Transition, TransitionController](
    model: Transition(),
    view: transitionView,
    controller: TransitionController(
      name: "Transition - FadeOut",
      onlyFadeOut: true,
    ),
  )

proc newFadeOnlyIn(): Menu[Transition, TransitionController] =
  Menu[Transition, TransitionController](
    model: Transition(),
    view: transitionView,
    controller: TransitionController(
      name: "Transition - FadeIn",
      reverse: true,
    ),
  )

method update(controller: TransitionController, dt: float) =
  controller.t += dt
  if controller.t >= transitionDuration:
    if controller.reverse or controller.onlyFadeOut:
      controller.shouldPop = true
    else:
      controller.shouldPush = true
      controller.reverse = true
      controller.t = 0.0

method pushMenus(controller: TransitionController): seq[MenuBase] =
  if controller.shouldPush and controller.menu != nil:
    result = @[
      controller.menu,
      downcast(newFadeOnlyIn()),
    ]
  controller.shouldPush = false

method shouldDrawBelow(controller: TransitionController): bool =
  true

type
  BattleData* = ref object of RootObj
    player: BattleEntity
    enemy: BattleEntity
    xp: int
    isEnemyTurn: bool
  BattleEntity* = object
    name: string
    health: int
    maxHealth: int
    color: Color
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

proc percent(event: BattleEvent): float =
  if event.duration == 0.0:
    0.0
  else:
    clamp(event.t / event.duration, 0, 1)

const
  textFloatHeight = 160.0
  textFloatTime = 1.25
  attackAnimDist = 250.0

proc newBattleEntity(name: string, health: int, color: Color): BattleEntity =
  BattleEntity(
    name: name,
    health: health,
    maxHealth: health,
    color: color,
  )

proc newPlayer(): BattleEntity =
  newBattleEntity("Player", 10, green)

proc newEnemy(): BattleEntity =
  newBattleEntity("Enemy", 3, red)

proc newBattleData(): BattleData =
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

proc battleEntityStatusNode(entity: BattleEntity, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      SpriteNode(
        pos: entity.offset,
        size: vec(40, 60),
        color: entity.color,
      ),
      BorderedTextNode(
        text: entity.name,
        pos: vec(0, 80),
      ),
      BorderedTextNode(
        text: $entity.health & " / " & $entity.maxHealth,
        pos: vec(0, 115),
      ),
    ],
  )

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

proc startAttack(controller: BattleController) =
  controller.eventQueue = @[
    newEvent(0.2) do (pct: float):
      controller.updateAttackAnimation(pct),
    newEvent do (pct: float):
      let damage = 1
      controller.processAttackDamage(damage),
    newEvent(0.2) do (pct: float):
      controller.updateAttackAnimation(1.0 - pct),
    newEvent do (pct: float):
      controller.updateMaybeKill()
      controller.battle.isEnemyTurn = not controller.battle.isEnemyTurn,
  ]

proc attackEnemy(controller: BattleController) =
  if controller.isClickReady:
    controller.startAttack()

proc pos(text: FloatingText): Vec =
  text.startPos - vec(0.0, textFloatHeight * text.t / textFloatTime)

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
        onClick: (proc() =
          controller.bufferClose = true
        ),
        children: @[BorderedTextNode(text: "Exit").Node],
      ),
      battleEntityStatusNode(battle.player, vec(0, 0)),
      BorderedTextNode(
        text: "XP: " & $battle.xp,
        pos: vec(0, 150),
      ),
      battleEntityStatusNode(battle.enemy, vec(300, 0)),
      Button(
        pos: vec(-45, 210),
        size: vec(60, 60),
        onClick: (proc() =
          controller.attackEnemy()
        ),
        children: @[BorderedTextNode(text: "Atk").Node],
      ),
    ] & floaties,
  )

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
    controller.startAttack()

  if controller.bufferClose:
    controller.shouldPop = true
    controller.bufferClose = false

method pushMenus(controller: BattleController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]

proc newBattleMenu(battle: BattleData): Menu[BattleData, BattleController] =
  Menu[BattleData, BattleController](
    model: battle,
    view: battleView,
    controller: newBattleController(battle),
  )

type
  TitleScreen = ref object of RootObj
  TitleScreenController = ref object of Controller
    battle: BattleData
    start: bool

method pushMenus(controller: TitleScreenController): seq[MenuBase] =
  if controller.start:
    controller.start = false
    let battleMenu = downcast(newBattleMenu(controller.battle))
    result = @[downcast(newTransitionMenu(battleMenu))]

proc mainMenuView(menu: TitleScreen, controller: TitleScreenController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "GAME TITLE",
      ),
      Button(
        pos: vec(600, 700),
        size: vec(300, 120),
        children: @[BorderedTextNode(text: "START").Node],
        onClick: (proc() =
          controller.start = true
        ),
      ),
    ],
  )

proc newTitleMenu(battle: BattleData): Menu[TitleScreen, TitleScreenController] =
  Menu[TitleScreen, TitleScreenController](
    model: TitleScreen(),
    view: mainMenuView,
    controller: TitleScreenController(battle: battle),
  )

##
##
##


type RpgFrontierGame* = ref object of Game
  battle: BattleData
  menu: Node

proc newRpgFrontierGame*(screenSize: Vec): RpgFrontierGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "RPG Frontier"
  result.battle = newBattleData()

method loadEntities*(game: RpgFrontierGame) =
  game.entities = @[]
  game.menus.push newTitleMenu(game.battle)

method draw*(renderer: RendererPtr, game: RpgFrontierGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: RpgFrontierGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRpgFrontierGame(screenSize), screenSize)
