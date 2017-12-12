import
  component/[
    sprite,
  ],
  entity,
  event,
  game_system,
  jsonparse,
  rect,
  util

type
  Animation* = ref AnimationObj
  AnimationObj* = object of Component
    data: AnimationData
    timer: float

  AnimationData* = object
    frames*: seq[Rect]
    duration*: float

autoObjectJsonProcs(AnimationData)
defineComponent(Animation, @["timer"])

proc setAnimation*(animation: Animation, data: AnimationData) =
  if animation.data != data:
    animation.timer = 0.0
  animation.data = data

proc startAnimation*(animation: Animation, data: AnimationData) =
  animation.data = data
  animation.timer = 0.0

proc pct(animation: Animation): float =
  if animation.data.duration <= 0.0:
    0.0
  else:
    animation.timer / animation.data.duration

defineSystem:
  priority = -100
  components = [Animation, Sprite]
  proc updateAnimation*(dt: float) =
    let frames = animation.data.frames
    if frames == nil or frames.len == 0:
      continue

    animation.timer += dt
    if animation.timer >= animation.data.duration:
      let numTimes = animation.pct.int
      animation.timer -= numTimes.float * animation.data.duration
    let
      frameIdx = (animation.data.frames.len.float * animation.pct).int
      frame = animation.data.frames[frameIdx]
    sprite.clipRect = frame
