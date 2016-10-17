import entity, vec

type Movement* = ref object of Component
  vel*: Vec
  usesGravity*: bool
  onGround*: bool
genComponentType(Movement)

const gravity* = 2_100.0
