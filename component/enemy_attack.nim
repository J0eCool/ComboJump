import sdl2

import
  component/bullet,
  component/collider,
  component/damage,
  component/enemy_proximity,
  component/movement,
  component/sprite,
  component/transform,
  entity,
  event,
  system,
  util,
  vec

type
  EnemyAttackKind* = enum
    melee
    ranged
  EnemyAttack* = ref object of Component
    kind*: EnemyAttackKind
    damage*: int
    size*: float
    attackDistance*: float
    attackSpeed*: float
    bulletSpeed*: float
    cooldownTimer: float

proc attackEntity*(enemyAttack: EnemyAttack, pos, dir: Vec): Entity =
  case enemyAttack.kind
  of melee:
    newEntity("EnemyAttack", [
            Damage(damage: enemyAttack.damage),
            Bullet(liveTime: 0.1, stayOnHit: true),
            Collider(layer: enemyBullet),
            Transform(
              pos: pos + dir * enemyAttack.attackDistance,
              size: vec(enemyAttack.size),
            ),
            Sprite(color: color(255, 0, 0, 255)),
          ])
  of ranged:
    newEntity("EnemyAttack", [
            Damage(damage: enemyAttack.damage),
            Bullet(liveTime: 3.0),
            Collider(layer: enemyBullet),
            Transform(
              pos: pos,
              size: vec(enemyAttack.size),
            ),
            Movement(vel: dir * enemyAttack.bulletSpeed),
            Sprite(color: color(255, 0, 0, 255)),
          ])

defineSystem:
  components = [EnemyAttack, EnemyProximity, Transform]
  proc updateEnemyAttack*(dt: float) =
    enemyAttack.cooldownTimer -= dt
    enemyProximity.isAttacking = enemyAttack.cooldownTimer > 0.0
    if enemyProximity.isInAttackRange and not enemyProximity.isAttacking:
      enemyAttack.cooldownTimer = 1.0 / enemyAttack.attackSpeed
      let attack = enemyAttack.attackEntity(transform.pos, enemyProximity.dirToPlayer)
      result.add event.Event(kind: addEntity, entity: attack)
