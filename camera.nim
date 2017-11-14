import
  vec

type Camera* = object
  pos*: Vec
  extra*: Vec
  screenSize*: Vec

proc offset*(camera: Camera): Vec =
  camera.pos + camera.extra
