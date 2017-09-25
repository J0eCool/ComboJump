import
  component/[
    bullet,
    collider,
    damage_component,
    movement,
    remove_when_offscreen,
    sprite,
    transform,
  ],
  quick_shoot/[
    shooter_stats,
  ],
  color,
  entity,
  event,
  game_system,
  input,
  vec

type
  PlayerShooterAttackObj* = object of ComponentObj
    shotCooldown: float
  PlayerShooterAttack* = ref PlayerShooterAttackObj

defineComponent(PlayerShooterAttack, @[])

proc bulletsToFire(transform: Transform): Events =
  let
    dir = vec(1, 0)
    bulletSpeed = 500.0
  result = @[Event(kind: addEntity, entity: newEntity("Bullet", [
    Damage(damage: 1),
    Bullet(liveTime: 3.0),
    Collider(layer: Layer.bullet),
    Transform(
      pos: transform.pos,
      size: vec(24),
    ),
    Movement(vel: dir * bulletSpeed),
    Sprite(color: rgb(0, 255, 72)),
    RemoveWhenOffscreen(),
  ]))]

defineSystem:
  components = [PlayerShooterAttack, Transform]
  proc updatePlayerShooterAttack*(stats: ShooterStats, dt: float, input: InputManager) =
    let attack = playerShooterAttack
    attack.shotCooldown -= dt
    if input.isMouseHeld and attack.shotCooldown <= 0.0:
      attack.shotCooldown = 1.0 / stats.attackSpeed
      result &= bulletsToFire(transform)
