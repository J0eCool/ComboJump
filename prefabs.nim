import
  component/camera_target,
  component/collider,
  component/damage,
  component/enemy_attack,
  component/enemy_movement,
  component/grid_control,
  component/health,
  component/health_bar,
  component/hud_menu,
  component/limited_quantity,
  component/mana,
  component/movement,
  component/player_health,
  component/progress_bar,
  component/sprite,
  component/targeting,
  component/target_shooter,
  component/text,
  component/transform,
  component/xp_on_death,
  entity,
  vec

proc newPlayer*(pos: Vec): Entity =
  newEntity("Player", [
    Transform(pos: pos,
              size: vec(76, 68)),
    Movement(),
    Collider(layer: player),
    GridControl(moveSpeed: 300.0),
    CameraTarget(vertical: true, offset: vec(0, 150)),
    PlayerHealth(),
    PlayerMana(),
    Targeting(),
    TargetShooter(),
    Sprite(textureName: "Wizard2.png"),
  ])

proc newHud*(): Entity =
  newEntity("Hud", [HudMenu().Component])

type EnemyKind* = enum
  goblin
  ogre

proc newGoblin(pos: Vec): Entity =
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
    XpOnDeath(xp: 5),
  ])

proc newOgre(pos: Vec): Entity =
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
    XpOnDeath(xp: 12),
  ])

proc newEnemy*(kind: EnemyKind, pos: Vec): Entity =
  case kind
  of goblin:
    newGoblin(pos)
  of ogre:
    newOgre(pos)