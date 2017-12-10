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
    data*: AnimationData
    timer: float

  AnimationData* = object
    frames*: seq[Rect]
    duration*: float

autoObjectJsonProcs(AnimationData)
defineComponent(Animation, @[])

proc pct(animation: Animation): float =
  animation.timer / animation.data.duration

defineSystem:
  components = [Animation, Sprite]
  proc updateAnimation*(dt: float) =
    if animation.data.frames == nil:
      animation.data = AnimationData(
        frames: @[
          rect( 8, 0, 8, 8),
          rect(16, 0, 8, 8),
        ],
        duration: 0.2,
      )
    animation.timer += dt
    if animation.timer >= animation.data.duration:
      let numTimes = animation.pct.int
      animation.timer -= numTimes.float * animation.data.duration
    let
      frameIdx = (animation.data.frames.len.float * animation.pct).int
      frame = animation.data.frames[frameIdx]
    sprite.clipRect = frame

