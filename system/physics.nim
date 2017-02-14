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
    var floorTransforms: seq[tuple[t: Transform, c: Collider]] = @[]
    entities.forComponents e, [
      Collider, c,
      Transform, t,
    ]:
      if c.layer == Layer.floor:
        floorTransforms.add((t, c))

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
                didCollide = true
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
              else:
                didCollide = false
              t.rect = r

              c.bufferedAdd f.entity
              fs.c.bufferedAdd e
