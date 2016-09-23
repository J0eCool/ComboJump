import
  component/health,
  component/mana,
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
      target.withComponent Health, h:
        t.size.x = b.baseSize * h.pct
      target.withComponent Mana, m:
        t.size.x = b.baseSize * m.pct
