import component

type Bullet* = ref object of Component
  damage*: int
  liveTime*: float
