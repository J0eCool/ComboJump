import math, macros, sdl2, times

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
  RpgBattleEntity* = object
    name: string
    health: int
    maxHealth: int
  RpgBattleData* = object
    player: RpgBattleEntity
    enemy: RpgBattleEntity
    xp: int

proc newBattleEntity(name: string, health: int): RpgBattleEntity =
  RpgBattleEntity(
    name: name,
    health: health,
    maxHealth: health,
  )

proc newPlayer(): RpgBattleEntity =
  newBattleEntity("Player", 10)

proc newEnemy(): RpgBattleEntity =
  newBattleEntity("Enemy", 5)

proc newBattleData(): RpgBattleData =
  RpgBattleData(
    player: newPlayer(),
    enemy: newEnemy(),
    xp: 0,
  )

proc battleEntityStatusNode(entity: RpgBattleEntity, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      BorderedTextNode(
        text: entity.name,
        pos: vec(),
      ).Node,
      BorderedTextNode(
        text: $entity.health & " / " & $entity.maxHealth,
        pos: vec(0, 35),
      ).Node,
    ],
  )

proc attackEnemy(battle: var RpgBattleData) =
  battle.enemy.health -= 1
  if battle.enemy.health <= 0:
    battle.xp += 1
    battle.enemy = newEnemy()

proc newBattleNode(battle: ptr RpgBattleData): Node =
  BindNode[RpgBattleData](
    pos: vec(400, 400),
    item: (proc(): RpgBattleData = battle[]),
    node: (proc(curr: RpgBattleData): Node =
      Node(
        children: @[
          battleEntityStatusNode(curr.player, vec(0, 0)),
          BorderedTextNode(
            text: "XP: " & $curr.xp,
            pos: vec(0, 70),
          ),
          battleEntityStatusNode(curr.enemy, vec(300, 0)),
          Button(
            pos: vec(300, 70),
            size: vec(240, 40),
            onClick: (proc() =
              battle[].attackEnemy()
            ),
            children: @[BorderedTextNode(text: "Attack").Node],
          ),
        ],
      )
    ),
  )

##
##
##


type RpgFrontierGame* = ref object of Game
  notifications: N10nManager
  battle: RpgBattleData
  menu: Node

proc newRpgFrontierGame*(screenSize: Vec): RpgFrontierGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "RPG Frontier"
  result.notifications = newN10nManager()
  result.battle = newBattleData()
  result.menu = newBattleNode(addr result.battle)

method loadEntities*(game: RpgFrontierGame) =
  game.entities = @[]

method onRemove*(game: RpgFrontierGame, entity: Entity) =
  game.notifications.add N10n(kind: entityRemoved, entity: entity)

method draw*(renderer: RendererPtr, game: RpgFrontierGame) =
  renderer.drawGame(game)

  renderer.draw(game.menu, game.resources)

method update*(game: RpgFrontierGame, dt: float) =
  game.dt = dt

  game.menu.update(game.menus, game.input)


when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRpgFrontierGame(screenSize), screenSize)
