import
  component/limited_quantity,
  component/progress_bar,
  component/text,
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
    let
      target = entities.firstEntityByName b.target
      heldTarget = entities.firstEntityByName b.heldTarget
      textTarget = entities.firstEntityByName b.textEntity
    if target == nil:
      t.size.x = 0
      continue

    target.withComponent LimitedQuantity, q:
      t.size.x = b.baseSize * q.pct

      if heldTarget != nil:
        heldTarget.withComponent Transform, tt:
          let w = b.baseSize * q.heldPct
          tt.pos.x = t.pos.x + t.size.x - w
          tt.size.x = w

      if textTarget != nil:
        textTarget.withComponent Text, txt:
          txt.setText($q.cur.int & " / " & $q.max.int)
