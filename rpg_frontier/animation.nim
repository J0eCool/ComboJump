import
  color,
  menu,
  util,
  vec

type
  AnimationCollection* = ref object
    floatingTexts: seq[FloatingText]
    vfxs: seq[Vfx]
    eventQueue: seq[Event]
    asyncQueue: seq[Event]
  FloatingText* = object
    text*: string
    startPos*: Vec
    t: float
  Event* = object
    duration*: float
    update*: EventUpdate
    t: float
  EventUpdate = proc(t: float)
  Vfx* = object
    sprite*: string
    pos*: Vec
    scale*: float
    update*: VfxUpdate
    duration*: float
    t: float
  VfxUpdate* = proc(vfx: var Vfx, t: float)

const
  textFloatHeight = 160.0
  textFloatTime = 1.25

proc newAnimationCollection*(): AnimationCollection =
  AnimationCollection(
    floatingTexts: @[],
    vfxs: @[],
    eventQueue: @[],
    asyncQueue: @[],
  )

proc percent*(event: Event): float =
  if event.duration == 0.0:
    0.0
  else:
    clamp(event.t / event.duration, 0, 1)

proc percent*(vfx: Vfx): float =
  if vfx.duration == 0.0:
    0.0
  else:
    clamp(vfx.t / vfx.duration, 0, 1)

proc pos*(text: FloatingText): Vec =
  text.startPos - vec(0.0, textFloatHeight * text.t / textFloatTime)

proc addFloatingText*(animation: AnimationCollection, text: FloatingText) =
  animation.floatingTexts.add text

proc addVfx*(animation: AnimationCollection, vfx: Vfx) =
  animation.vfxs.add vfx

proc queueEvent*(animation: AnimationCollection, duration: float, update: EventUpdate) =
  animation.eventQueue.add Event(
    duration: duration,
    update: update,
  )
proc queueEvent*(animation: AnimationCollection, update: EventUpdate) =
  animation.queueEvent(0.0, update)
proc wait*(animation: AnimationCollection, duration: float) =
  animation.queueEvent(duration, (proc(t: float) = discard))

proc queueAsync*(animation: AnimationCollection, duration: float, update: EventUpdate) =
  animation.asyncQueue.add Event(
    duration: duration,
    update: update,
  )

proc notBlocking*(animation: AnimationCollection): bool =
  animation.eventQueue.len == 0

proc updateFloatingText(animation: AnimationCollection, dt: float) =
  var newFloaties: seq[FloatingText] = @[]
  for text in animation.floatingTexts.mitems:
    text.t += dt
    if text.t <= textFloatTime:
      newFloaties.add text
  animation.floatingTexts = newFloaties

proc updateVfx(animation: AnimationCollection, dt: float) =
  var newVfxs: seq[Vfx] = @[]
  for vfx in animation.vfxs.mitems:
    vfx.t += dt
    vfx.update(vfx, vfx.percent)
    if vfx.t <= vfx.duration:
      newVfxs.add vfx
  animation.vfxs = newVfxs

proc updateEventQueue(animation: AnimationCollection, dt: float) =
  if animation.eventQueue.len > 0:
    animation.eventQueue[0].t += dt
    let cur = animation.eventQueue[0]
    if cur.t > cur.duration:
      animation.eventQueue.delete(0)
    cur.update(cur.percent)

proc updateAsyncQueue(animation: AnimationCollection, dt: float) =
  var i = animation.asyncQueue.len - 1
  while i >= 0:
    animation.asyncQueue[i].t += dt
    let cur = animation.asyncQueue[i]
    cur.update(cur.percent)
    if cur.t > cur.duration:
      animation.asyncQueue.delete(i)
    i -= 1

proc update*(animation: AnimationCollection, dt: float) =
  animation.updateFloatingText(dt)
  animation.updateVfx(dt)
  animation.updateEventQueue(dt)
  animation.updateAsyncQueue(dt)

proc nodes*(animation: AnimationCollection): seq[Node] =
  result = @[]
  for text in animation.floatingTexts:
    result.add BorderedTextNode(
      text: text.text,
      pos: text.pos,
    )
  for vfx in animation.vfxs:
    result.add SpriteNode(
      pos: vfx.pos,
      textureName: vfx.sprite,
      scale: vfx.scale,
    )
