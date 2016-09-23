import
  component/mana,
  entity

proc regenMana*(entities: seq[Entity], dt: float) =
  entities.forComponents e, [
    Mana, m,
  ]:
    m.partial += 12 * dt
    let delta = m.partial.int
    m.cur = min(m.cur + delta, m.max)
    m.partial -= delta.float