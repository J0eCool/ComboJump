import tables

import
  component/[
    animation,
  ],
  entity,
  event,
  game_system,
  jsonparse,
  rect,
  util

type
  AnimationBank* = ref AnimationBankObj
  AnimationBankObj* = object of Component
    animations: Table[string, AnimationData]

defineComponent(AnimationBank, @[])

proc hasAnimation(bank: AnimationBank, key: string): bool =
  bank.animations.hasKey(key)

proc getAnimation(bank: AnimationBank, key: string): AnimationData =
  bank.animations[key]

proc setAnimation*(bank: AnimationBank, animation: Animation, key: string) =
  if not bank.hasAnimation(key):
    return
  animation.setAnimation(bank.getAnimation(key))

proc startAnimation*(bank: AnimationBank, animation: Animation, key: string) =
  if not bank.hasAnimation(key):
    return
  animation.startAnimation(bank.getAnimation(key))
