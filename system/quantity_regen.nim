import
  component/health,
  component/limited_quantity,
  component/mana,
  entity,
  event

proc regenLimitedQuantities*(entities: seq[Entity], dt: float): Events =
  entities.forComponents e, [
    Health, h,
  ]:
    h.regen dt

  entities.forComponents e, [
    Mana, m,
  ]:
    m.regen dt
