type Component* = ref object of RootObj

proc C*(c: Component): seq[Component] =
  @[c]
