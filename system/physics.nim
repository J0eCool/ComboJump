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
  ColliderData = tuple[entity: Entity, rect: Rect, collider: Collider]
  Ray* = object
    pos*: Vec
    dir*: Vec
    dist*: float
  RaycastHit* = object
    pos*: Vec
    normal*: Vec
    distance*: float

# New system:
# toMove = vel*dt
# while toMove.length > 0:
#   Raycast from each point on the entity through
#   Find the shortest-distance collision, move by that distance
#   Subtract moved distance from toMove, zero vel direction normal to collision

proc setShortest(toSet: var Option[RaycastHit], hit: RaycastHit) =
  # TODO: only set toSet when toSet is None or hit distance is shorter
  toSet = hit.makeJust

proc intersection*(ray: Ray, rect: Rect): Option[RaycastHit] =
  let d = ray.dir.unit * ray.dist
  proc calculateIntersection(
      toSet: var Option[RaycastHit],
      target = 0.0,
      normal = vec(),
     ) =
    let
      isX = normal.x != 0
      (main, sub) = if isX: (getX, getY) else: (getY, getX)
      m = d.sub / d.main
      dx = -normal.main * (target - ray.pos.main)
      y = m * dx + ray.pos.sub
    if dx > 0.0 and dx <= ray.dist and
        ((isX and y >= rect.top and y <= rect.bottom) or
         (not isX and y >= rect.left and y <= rect.right)):
      let
        pos = if isX: vec(target, y) else: vec(y, target)
        distance = ray.pos.distance(pos)
      toSet.setShortest RaycastHit(
        pos: pos,
        normal: normal,
        distance: distance,
      )

  if d.x > 0:
    result.calculateIntersection(
      target = rect.left,
      normal = vec(-1, 0),
    )
  elif d.x < 0:
    result.calculateIntersection(
      target = rect.right,
      normal = vec(1, 0),
    )
  if d.y > 0:
    result.calculateIntersection(
      target = rect.top,
      normal = vec(0, -1),
    )
  elif d.y < 0:
    result.calculateIntersection(
      target = rect.bottom,
      normal = vec(0, 1),
    )

proc raycast*(ray: Ray, colliders: seq[Rect]): seq[RaycastHit] =
  # Find all intersections between ray start and end line segment
  # Sort result by distance
  @[]

defineSystem:
  priority = -1
  proc physics*(dt: float) =
    var
      floorTransforms: seq[ColliderData] = @[]
      platformTransforms: seq[ColliderData] = @[]
    entities.forComponents entity, [
      Collider, collider,
      Transform, transform,
    ]:
      proc add(rect: Rect) =
        let data = (entity, rect, collider)
        if collider.layer == Layer.floor:
          floorTransforms.add(data)
        elif collider.layer == Layer.oneWayPlatform:
          platformTransforms.add(data)
      let roomViewer = entity.getComponent(RoomViewer)
      if roomViewer == nil:
        add(transform.globalRect)
        continue

      let
        data = roomViewer.data
        size = roomViewer.tileSize
      for x in 0..<data.len:
        for y in 0..<data[x].len:
          if data[x][y]:
            let pos = transform.globalPos + vec(x, y) * size
            add(rect(pos, size))

    entities.forComponents e, [
      Movement, m,
      Transform, t,
    ]:
      if m.usesGravity:
        m.vel.y += gravity * dt
      let
        oldRect = t.globalRect
        toMove = m.vel * dt
      t.pos += toMove

      m.onGround = false
      e.withComponent Collider, c:
        if c.layer.canCollideWith Layer.floor:
          for fs in floorTransforms:
            if e != fs.entity and t.globalRect.intersects fs.rect:
              let
                fr = fs.rect
                s = t.size
              var
                r = t.globalRect
              if intersects(oldRect.centerBottom, r.centerBottom,
                            fr.topLeft - s.vecX, fr.topRight + s.vecX):
                r.bottom = fr.top
                m.onGround = true
                m.vel.y = 0
              elif intersects(oldRect.centerTop, r.centerTop,
                              fr.bottomLeft - s.vecX, fr.bottomRight + s.vecX):
                r.top = fr.bottom
                m.vel.y = 0
              elif intersects(oldRect.centerLeft, r.centerLeft,
                              fr.topRight - s.vecY, fr.bottomRight + s.vecY):
                r.left = fr.right
              elif intersects(oldRect.centerRight, r.centerRight,
                              fr.topLeft - s.vecY, fr.bottomLeft + s.vecY):
                r.right = fr.left
              t.globalPos = r.pos

              c.bufferedAdd fs.entity
              fs.collider.bufferedAdd e

          if m.isFalling and (not m.canDropDown):
            for fs in platformTransforms:
              let
                feetHeight = 2.0
                feet = rect(t.pos + vec(0.0, (t.size.x - feetHeight) / 2),
                            vec(t.size.x, feetHeight))
              if e != fs.entity and feet.intersects fs.rect:
                let
                  fr = fs.rect
                  s = t.size
                var
                  r = t.globalRect
                r.bottom = fr.top
                m.onGround = true
                m.vel.y = 0
                t.globalPos = r.pos

                c.bufferedAdd fs.entity
                fs.collider.bufferedAdd e
