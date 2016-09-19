import component, vec

type Movement* = ref object of Component
  vel*: Vec
  usesGravity*: bool
  onGround*: bool

const gravity* = 2_100.0
