import
  component/mana,
  component/limited_quantity,
  entity

proc regenLimitedQuantities*(entities: seq[Entity], dt: float) =
  entities.forComponents e, [
    LimitedQuantity, q,
  ]:
    q.regen dt
