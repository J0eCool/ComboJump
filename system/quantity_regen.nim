import
  component/mana,
  component/limited_quantity,
  entity,
  event

proc regenLimitedQuantities*(entities: seq[Entity], dt: float): Events =
  entities.forComponents e, [
    LimitedQuantity, q,
  ]:
    q.regen dt
