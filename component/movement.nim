import component, ../vec

type Movement* = ref object of Component
  vel*: Vec
