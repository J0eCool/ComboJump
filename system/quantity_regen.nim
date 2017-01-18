import
  component/health,
  component/limited_quantity,
  component/mana,
  entity,
  event,
  game_system

defineSystem:
  proc regenLimitedQuantities*(dt: float) =
    entities.forComponents e, [
      Health, h,
    ]:
      h.regen dt

    entities.forComponents e, [
      Mana, m,
    ]:
      m.regen dt
