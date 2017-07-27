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
    offset: Vec
  BattleController* = ref object of Controller
    battle: BattleData
    floatingTexts: seq[FloatingText]
    eventQueue: seq[BattleEvent]
  FloatingText* = object
    text*: string
    startPos*: Vec
    t: float
  BattleEventKind* = enum
    attackAnimation
    dealDamage
  BattleEvent* = object
    case kind: BattleEventKind
    of attackAnimation:
      discard
    of dealDamage:
      damage*: int
    duration*: float
    t: float

proc percent(event: BattleEvent): float =
  if event.duration == 0.0:
    0.0
  else:
    event.t / event.duration

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

proc attackEnemy(battle: BattleController) =
  if battle.eventQueue.len != 0:
    return

  battle.eventQueue = @[
    BattleEvent(kind: attackAnimation, duration: 0.2),
    BattleEvent(kind: dealDamage, damage: 1),
  ]

proc updateAttackAnimation(controller: BattleController, pct: float) =
  controller.battle.player.offset = vec(attackAnimDist * pct, 0.0)
  if pct >= 1.0:
    controller.battle.player.offset = vec()

proc processAttackDamage(controller: BattleController, damage: int) =
  controller.battle.enemy.health -= damage
  controller.floatingTexts.add FloatingText(
    text: $damage,
    startPos: vec(300, 0) + randomVec(30.0),
  )
  if controller.battle.enemy.health <= 0:
    let xp = 1
    controller.floatingTexts.add FloatingText(
      text: "+" & $xp & "xp",
      startPos: vec(0, 150) + randomVec(5.0),
    )
    controller.battle.xp += xp
    controller.battle.enemy = newEnemy()

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
    case cur.kind
    of attackAnimation:
      controller.updateAttackAnimation(cur.percent)
    else:
      discard
    if cur.t > cur.duration:
      case cur.kind
      of dealDamage:
        controller.processAttackDamage(cur.damage)
      else:
        discard
      controller.eventQueue.delete(0)

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
  game.menus.add Menu[BattleData, BattleController](
    model: game.battle,
    view: battleView,
    controller: newBattleController(game.battle),
  )

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
