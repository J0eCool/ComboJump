import sdl2

import
  component/bullet,
  component/collider,
  component/damage,
  component/enemy_proximity,
  component/sprite,
  component/transform,
  entity,
  event,
  system,
  util,
  vec

type
  EnemyAttack* = ref object of Component
    damage*: int
    size*: float
    attackDistance*: float
    attackSpeed*: float
    cooldownTimer: float

defineSystem:
  proc updateEnemyAttack*(dt: float) =
    result = @[]
    entities.forComponents entity, [
      EnemyAttack, enemyAttack,
      EnemyProximity, enemyProximity,
      Transform, transform,
    ]:
      enemyAttack.cooldownTimer -= dt
      enemyProximity.isAttacking = enemyAttack.cooldownTimer > 0.0
      if enemyProximity.isInAttackRange and not enemyProximity.isAttacking:
        enemyAttack.cooldownTimer = 1.0 / enemyAttack.attackSpeed
        let
          pos = transform.pos + enemyProximity.dirToPlayer * enemyAttack.attackDistance
          swing = newEntity("EnemyAttack", [
            Damage(damage: enemyAttack.damage),
            Bullet(liveTime: 0.1, stayOnHit: true),
            Collider(layer: enemyBullet),
            Transform(pos: pos, size: vec(enemyAttack.size)),
            Sprite(color: color(255, 0, 0, 255)),
          ])
        result.add event.Event(kind: addEntity, entity: swing)
