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
  rect,
  util,
  vec

type ColliderData = tuple[entity: Entity, rect: Rect, collider: Collider]

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
