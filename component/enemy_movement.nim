import
  component/[
    collider,
    enemy_proximity,
    movement,
    transform,
  ],
  system/[
    physics,
  ],
  entity,
  event,
  game_system,
  option,
  rect,
  util,
  vec

type
  EnemyMoveTowardsObj* = object of ComponentObj
    moveSpeed*: float
  EnemyMoveTowards* = ref EnemyMoveTowardsObj

  EnemyMovePacingObj* = object of ComponentObj
    moveSpeed*: float
    facingSign*: float
    stayOnPlatforms*: bool
  EnemyMovePacing* = ref EnemyMovePacingObj

defineComponent(EnemyMoveTowards, @[])
defineComponent(EnemyMovePacing, @[])

defineSystem:
  components = [EnemyMoveTowards, EnemyProximity, Movement]
  proc updateEnemyMoveTowards*(dt: float) =
    if enemyProximity.isInRange and not enemyProximity.isAttacking:
      movement.vel = enemyMoveTowards.moveSpeed * enemyProximity.dirToPlayer
    else:
      movement.vel = vec(0)

defineSystem:
  components = [EnemyMovePacing, Movement, Collider, Transform]
  proc updateEnemyMovePacing*(dt: float, terrain: TerrainData) =
    let move = enemyMovePacing
    if move.facingSign == 0:
      move.facingSign = -1.0
    if collider.touchingLeft:
      move.facingSign = 1.0
    elif collider.touchingRight:
      move.facingSign = -1.0
    elif move.stayOnPlatforms:
      let
        dist = transform.size.y / 2 + 2.0
        down = vec(0, 1)
        rect = transform.globalRect
        hitLeft = terrain.raycast(Ray(pos: rect.centerLeft, dir: down, dist: dist))
        hitRight = terrain.raycast(Ray(pos: rect.centerRight, dir: down, dist: dist))
      if hitLeft.isJust xor hitRight.isJust:
        move.facingSign = if hitLeft.isJust: -1.0 else: 1.0
    movement.vel.x = move.moveSpeed * move.facingSign
