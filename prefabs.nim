import
  component/camera_target,
  component/collider,
  component/damage,
  component/enemy_movement,
  component/grid_control,
  component/health,
  component/health_bar,
  component/limited_quantity,
  component/mana,
  component/movement,
  component/player_control,
  component/progress_bar,
  component/sprite,
  component/targeting,
  component/target_shooter,
  component/text,
  component/transform,
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
    Targeting(),
    TargetShooter(),
    Sprite(textureName: "Wizard2.png"),
  ])

type EnemyKind* = enum
  goblin
  ogre

proc newGoblin(pos: Vec): Entity =
  newEntity("Goblin", [
    Transform(pos: pos,
              size: vec(48, 56)),
    Movement(),
    newHealth(20),
    Collider(layer: enemy),
    Sprite(textureName: "Goblin.png"),
    HealthBar(),
  ])

proc newOgre(pos: Vec): Entity =
  newEntity("Ogre", [
    Transform(pos: pos,
              size: vec(52, 80)),
    Movement(),
    newHealth(50),
    Collider(layer: enemy),
    Sprite(textureName: "Ogre.png"),
    HealthBar(),
  ])

proc newEnemy*(kind: EnemyKind, pos: Vec): Entity =
  case kind
  of goblin:
    newGoblin(pos)
  of ogre:
    newOgre(pos)