import
  component/transform,
  entity,
  event,
  input,
  option,
  rect,
  vec

type Clickable* = ref object of Component
  held*: bool

proc updateClicked*(entities: Entities, input: InputManager): Events =
  entities.forComponents e, [
    Clickable, c,
    Transform, t,
  ]:
    c.held = false
    input.clickHeldPos.bindAs click:
      if t.rect.contains click:
        c.held = true
