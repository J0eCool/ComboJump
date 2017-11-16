import
  component/[
    collider,
    movement,
    room_viewer,
    transform,
  ],
  mapgen/tile_room,
  entity,
  event,
  game_system,
  option,
  rect,
  util,
  vec

type
  TerrainData* = object
    rects: seq[Rect]
    entities: seq[Entity]

  Ray* = object
    pos*: Vec
    dir*: Vec
    dist*: float
  RaycastHit* = object
    pos*: Vec
    normal*: Vec
    distance*: float

proc setShortest(toSet: var Option[RaycastHit], hit: RaycastHit) =
  if toSet.isNone:
    toSet = hit.makeJust
    return
  toSet.bindAs cur:
    if hit.distance < cur.distance:
      toSet = hit.makeJust

proc setShortest(toSet: var Option[RaycastHit], maybeHit: Option[RaycastHit]) =
  maybeHit.bindAs hit:
    toSet.setShortest(hit)

proc intersection*(ray: Ray, rect: Rect): Option[RaycastHit] =
  let d = ray.dir.unit * ray.dist
  proc calculateIntersection(
      toSet: var Option[RaycastHit],
      toHitEdge: var bool,
      target = 0.0,
      normal = vec(),
     ) =
    let
      isX = normal.x != 0
      (main, sub) = if isX: (getX, getY) else: (getY, getX)
      m = d.sub / d.main
      dx = -normal.main * (target - ray.pos.main)
      y = m * dx + ray.pos.sub
    if dx >= 0.0 and dx <= ray.dist and
        ((isX and y >= rect.top and y <= rect.bottom) or
         (not isX and y >= rect.left and y <= rect.right)):
      let
        pos = if isX: vec(target, y) else: vec(y, target)
        distance = ray.pos.distance(pos)
      toHitEdge = ((isX and (y == rect.top or y == rect.bottom)) or
                 (not isX and (y == rect.left or y == rect.right)))

      var hit = RaycastHit(
        pos: pos,
        normal: normal,
        distance: distance,
      )
      if isX or toSet.isNone:
        toSet = hit.makeJust
      else:
        toSet.bindAs pre:
          hit.normal = unit(hit.normal + pre.normal)
          toSet = hit.makeJust

  var
    hitEdgeX = false
    hitEdgeY = false
  if d.x > 0:
    result.calculateIntersection(
      hitEdgeX,
      target = rect.left,
      normal = vec(-1, 0),
    )
  elif d.x < 0:
    result.calculateIntersection(
      hitEdgeX,
      target = rect.right,
      normal = vec(1, 0),
    )
  if d.y > 0:
    result.calculateIntersection(
      hitEdgeY,
      target = rect.top,
      normal = vec(0, -1),
    )
  elif d.y < 0:
    result.calculateIntersection(
      hitEdgeY,
      target = rect.bottom,
      normal = vec(0, 1),
    )
  if hitEdgeX xor hitEdgeY:
    result = makeNone[RaycastHit]()

proc raycast*(terrain: TerrainData, ray: Ray): Option[RaycastHit] =
  for collider in terrain.rects:
    let col = ray.intersection(collider)
    col.bindAs hit:
      result.setShortest hit

defineSystem:
  priority = -2
  proc collectTerrain*(terrain: var TerrainData) =
    terrain = TerrainData(
      rects: @[],
      entities: @[],
    )
    entities.forComponents entity, [
      Collider, collider,
      Transform, transform,
    ]:
      let roomViewer = entity.getComponent(RoomViewer)
      if roomViewer == nil:
        if collider.layer == Layer.floor:
          terrain.rects.add transform.globalRect
          terrain.entities.add entity
        continue

      let
        data = roomViewer.data
        size = roomViewer.tileSize
      for x in 0..<data.len:
        for y in 0..<data[x].len:
          if data[x][y]:
            let pos = transform.globalPos + vec(x, y) * size
            terrain.rects.add rect(pos, size)
            terrain.entities.add entity

    assert terrain.rects.len == terrain.entities.len

defineSystem:
  priority = -1
  proc physics*(dt: float, terrain: TerrainData) =
    proc collidedEntity(cur: Rect): Entity =
      for i in 0..<terrain.rects.len:
        let col = terrain.rects[i]
        if col.intersects(cur):
          return terrain.entities[i]
      return nil

    proc binarySearch(rect: var Rect, pre: Vec, startedCollided: bool) =
      var
        lo = pre
        hi = rect.pos
      for _ in 0..<10:
        rect.pos = (hi + lo) / 2
        if rect.collidedEntity != nil xor startedCollided:
          hi = rect.pos
        else:
          lo = rect.pos
      if rect.collidedEntity != nil:
        if startedCollided:
          rect.pos = hi
        else:
          rect.pos = lo

    # Do collisions
    entities.forComponents entity, [
      Movement, movement,
      Transform, transform,
    ]:
      if movement.usesGravity:
        movement.vel.y += gravity * dt


      entity.withComponent Collider, collider:
        collider.touchingDown = false
        collider.touchingRight = false
        collider.touchingLeft = false

        var
          rect = transform.globalRect
          toMove = movement.vel * dt
        let size = rect.size

        if not collider.layer.canCollideWith Layer.floor:
          transform.pos += toMove
          continue

        if rect.collidedEntity != nil:
          # If starting in ground, need to fix
          var fixes = [
            vec(1, 0),
            vec(-1, 0),
            vec(0, 1),
            vec(0, -1),
          ]
          let pre = rect.pos
          var colliding = true
          while colliding:
            for i in 0..<4:
              rect.pos = pre + fixes[i]
              if rect.collidedEntity == nil:
                colliding = false
                break
              fixes[i] = fixes[i] * 2
          rect.binarySearch(pre, startedCollided=true)

        var atMost = 2
        while toMove.length2 > 0.001:
          atMost -= 1
          let pre = rect.pos
          rect += toMove
          let collided = rect.collidedEntity
          if collided != nil:
            rect.binarySearch(pre, startedCollided=false)
          toMove -= rect.pos - pre
          if collided != nil:
            let hitX = rect(rect.pos + vec(1 * sign(toMove.x), 0), size).collidedEntity != nil
            if hitX:
              if movement.vel.x > 0:
                collider.touchingRight = true
              elif movement.vel.x < 0:
                collider.touchingLeft = true
              toMove.x = 0.0
              movement.vel.x = 0.0
            else:
              if movement.vel.y >= 0:
                collider.touchingDown = true
              toMove.y = 0.0
              movement.vel.y = 0.0
            collider.bufferedCollisions.add collided

        transform.globalPos = rect.pos

