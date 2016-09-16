import component, vec

type Transform* = ref object of Component
  pos*, size*: Vec
