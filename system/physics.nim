import
  component/[
    collider,
    movement,
    transform,
  ],
  entity,
  event,
  game_system,
  rect,
  util,
  vec

defineSystem:
  priority = -1
  proc physics*(dt: float) =
    var
      floorTransforms: seq[tuple[t: Transform, c: Collider]] = @[]
      platformTransforms: seq[tuple[t: Transform, c: Collider]] = @[]
    entities.forComponents e, [
      Collider, c,
      Transform, t,
    ]:
      if c.layer == Layer.floor:
        floorTransforms.add((t, c))
      elif c.layer == Layer.oneWayPlatform:
        platformTransforms.add((t, c))

    entities.forComponents e, [
      Movement, m,
      Transform, t,
    ]:
      if m.usesGravity:
        m.vel.y += gravity * dt
      let
        oldRect = t.rect
        toMove = m.vel * dt
      t.pos += toMove

      m.onGround = false
      e.withComponent Collider, c:
        if c.layer.canCollideWith Layer.floor:
          for fs in floorTransforms:
            let f = fs.t
            if t != f and t.rect.intersects f.rect:
              let
                fr = f.rect
                s = t.size
              var
                r = t.rect
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
              t.rect = r

              c.bufferedAdd f.entity
              fs.c.bufferedAdd e

          if m.isFalling and (not m.canDropDown):
            for fs in platformTransforms:
              let
                f = fs.t
                feetHeight = 2.0
                feet = rect(t.pos + vec(0.0, (t.size.x - feetHeight) / 2),
                            vec(t.size.x, feetHeight))
              if t != f and feet.intersects f.rect:
                let
                  fr = f.rect
                  s = t.size
                var
                  r = t.rect
                r.bottom = fr.top
                m.onGround = true
                m.vel.y = 0
                t.rect = r

                c.bufferedAdd f.entity
                fs.c.bufferedAdd e
