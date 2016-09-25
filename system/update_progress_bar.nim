import
  component/limited_quantity,
  component/progress_bar,
  component/transform,
  entity,
  util

proc updateProgressBars*(entities: seq[Entity]) =
  entities.forComponents e, [
    ProgressBar, b,
    Transform, t,
  ]:
    if b.baseSize < 0:
      b.baseSize = t.size.x
    let target = entities.firstEntityByName b.target
    if target == nil:
      t.size.x = 0
    else:
      target.withComponent LimitedQuantity, q:
        t.size.x = b.baseSize * q.pct
