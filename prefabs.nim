import
  component/[
    collider,
    damage,
    enemy_attack,
    enemy_movement,
    enemy_proximity,
    enemy_stats,
    grid_control,
    health,
    health_bar,
    hud_menu,
    limited_quantity,
    locked_door,
    mana,
    movement,
    player_health,
    progress_bar,
    sprite,
    text,
    transform,
  ],
  enemy_kind,
  entity,
  entity_json,
  jsonparse,
  vec

proc loadPrefab*(name: string): Entity =
  let
    path = "assets/prefabs/" & name & ".json"
    json = readJSONFile(path)
  fromJSON(result, json)

proc newPlayer*(pos: Vec): Entity =
  result = loadPrefab("Player")
  let transform = result.getComponent(Transform)
  transform.pos = pos

proc newHud*(): Entity =
  newEntity("Hud", [HudMenu().Component])

proc newGoblin(level: int, pos: Vec): Entity =
  newEntity("Goblin", [
    Transform(pos: pos,
              size: vec(48, 56)),
    Movement(),
    EnemyProximity(
      targetMinRange: 75.0,
      targetRange: 500.0,
      attackRange: 95.0,
    ),
    EnemyAttack(
      damage: 12,
      attackSpeed: 1.2,
      size: 50.0,
      attackDistance: 75.0,
    ),
    EnemyMoveTowards(moveSpeed: 180.0),
    newHealth(20),
    Collider(layer: enemy),
    Sprite(textureName: "Goblin.png"),
    HealthBar(),
    EnemyStats(
      name: "Goblin",
      kind: goblin,
      level: level,
      xp: 5,
    ),
  ])

proc newOgre(level: int, pos: Vec): Entity =
  newEntity("Ogre", [
    Transform(pos: pos,
              size: vec(52, 80)),
    Movement(),
    EnemyProximity(
      targetMinRange: 100.0,
      targetRange: 500.0,
      attackRange: 120.0,
    ),
    EnemyAttack(
      damage: 30,
      attackSpeed: 0.9,
      size: 70.0,
      attackDistance: 90.0,
    ),
    EnemyMoveTowards(moveSpeed: 130.0),
    newHealth(50),
    Collider(layer: enemy),
    Sprite(textureName: "Ogre.png"),
    HealthBar(),
    EnemyStats(
      name: "Ogre",
      kind: ogre,
      level: level,
      xp: 12,
    ),
  ])

proc newMushroom(level: int, pos: Vec): Entity =
  newEntity("Mushroom", [
    Transform(pos: pos,
              size: vec(52, 56)),
    EnemyProximity(
      attackRange: 600.0,
    ),
    EnemyAttack(
      kind: ranged,
      damage: 15,
      attackSpeed: 0.8,
      size: 30.0,
      bulletSpeed: 500.0,
    ),
    newHealth(30),
    Collider(layer: enemy),
    Sprite(textureName: "Mushroom.png"),
    HealthBar(),
    EnemyStats(
      name: "Mushroom",
      kind: mushroom,
      level: level,
      xp: 10,
    ),
  ])

proc newEnemy*(kind: EnemyKind, level: int, pos: Vec): Entity =
  case kind
  of goblin: newGoblin(level, pos)
  of ogre: newOgre(level, pos)
  of mushroom: newMushroom(level, pos)
