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
      b.basePos = t.pos.x
      b.baseSize = t.size.x
    let
      q = b.target(entities)
      heldTarget = entities.firstEntityByName b.heldTarget
      textTarget = entities.firstEntityByName b.textEntity
    if q == nil:
      t.size.x = 0
      continue

    let w = b.baseSize * q.pct
    t.size.x = w
    t.pos.x = b.basePos - b.baseSize/2 + w/2

    if heldTarget != nil:
      heldTarget.withComponent Transform, tt:
        let w = b.baseSize * q.heldPct
        tt.pos.x = t.pos.x + t.size.x/2 - w/2
        tt.size.x = w

    if textTarget != nil:
      textTarget.withComponent Text, txt:
        txt.text = $q.cur.int & " / " & $q.max.int
