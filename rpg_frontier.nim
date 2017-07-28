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
  notifications,
  program,
  resources,
  vec,
  util

##
## TODO: put these in the right files
##

import menu

type
  BattleData* = ref object of RootObj
    player: BattleEntity
    enemy: BattleEntity
    xp: int
  BattleEntity* = object
    name: string
    health: int
    maxHealth: int
    color: Color
  BattleController* = ref object of Controller
    battle: BattleData
    floatingTexts: seq[FloatingText]
    eventQueue: seq[BattleEvent]
    playerOffset: Vec
    enemyOffset: Vec
    didKill: bool
    shouldClose: bool
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
  newBattleEntity("Enemy", 5, red)

proc newBattleData(): BattleData =
  BattleData(
    player: newPlayer(),
    enemy: newEnemy(),
    xp: 0,
  )

proc newBattleController(battle: BattleData): BattleController =
  BattleController(
    battle: battle,
    floatingTexts: @[],
    eventQueue: @[],
  )

proc battleEntityStatusNode(entity: BattleEntity, pos, offset: Vec): Node =
  Node(
    pos: pos,
    children: @[
      SpriteNode(
        pos: offset,
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
  controller.playerOffset = vec(attackAnimDist * pct, 0.0)

proc processAttackDamage(controller: BattleController, damage: int) =
  controller.battle.enemy.health -= damage
  controller.floatingTexts.add FloatingText(
    text: $damage,
    startPos: vec(300, 0) + randomVec(30.0),
  )
  controller.didKill = controller.battle.enemy.health <= 0

proc newEvent(duration: float, update: EventUpdate): BattleEvent =
  BattleEvent(
    duration: duration,
    update: update,
  )
proc newEvent(update: EventUpdate): BattleEvent =
  newEvent(0.0, update)

proc attackEnemy(controller: BattleController) =
  if controller.eventQueue.len != 0:
    return

  controller.eventQueue = @[
    newEvent(0.2) do (pct: float):
      controller.updateAttackAnimation(pct),
    newEvent do (pct: float):
      let damage = 1
      controller.processAttackDamage(damage),
    newEvent(0.2) do (pct: float):
      controller.updateAttackAnimation(1.0 - pct),
    newEvent do (pct: float):
      let didKill = controller.didKill
      controller.didKill = false
      if didKill:
        let xp = 1
        controller.floatingTexts.add FloatingText(
          text: "+" & $xp & "xp",
          startPos: vec(350, -50) + randomVec(5.0),
        )
        controller.battle.xp += xp
        let dx = random(300.0, 700.0)
        controller.eventQueue &= @[
          newEvent(0.8) do (pct: float):
            controller.enemyOffset = vec(dx * pct, -2200.0 * pct * (0.25 - pct)),
          newEvent do (pct: float):
            controller.enemyOffset = vec()
            controller.battle.enemy = newEnemy(),
        ],
  ]

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
          controller.shouldClose = true
        ),
        children: @[BorderedTextNode(text: "Exit").Node],
      ),
      battleEntityStatusNode(battle.player, vec(0, 0), controller.playerOffset),
      BorderedTextNode(
        text: "XP: " & $battle.xp,
        pos: vec(0, 150),
      ),
      battleEntityStatusNode(battle.enemy, vec(300, 0), controller.enemyOffset),
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

method shouldPop(controller: BattleController): bool =
  controller.shouldClose

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

method pushMenu(controller: TitleScreenController): MenuBase =
  if controller.start:
    controller.start = false
    result = downcast(newBattleMenu(controller.battle))

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
  notifications: N10nManager
  battle: BattleData
  menu: Node

proc newRpgFrontierGame*(screenSize: Vec): RpgFrontierGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "RPG Frontier"
  result.notifications = newN10nManager()
  result.battle = newBattleData()

method loadEntities*(game: RpgFrontierGame) =
  game.entities = @[]
  game.menus.push newTitleMenu(game.battle)

method onRemove*(game: RpgFrontierGame, entity: Entity) =
  game.notifications.add N10n(kind: entityRemoved, entity: entity)

method draw*(renderer: RendererPtr, game: RpgFrontierGame) =
  renderer.drawGame(game)

  renderer.draw(game.menus, game.resources)

method update*(game: RpgFrontierGame, dt: float) =
  game.dt = dt

  game.menus.update(dt, game.input)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRpgFrontierGame(screenSize), screenSize)
