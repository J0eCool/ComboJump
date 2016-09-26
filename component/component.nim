type Component* = ref object of RootObj

proc C*(c: Component): seq[Component] =
  @[c]

proc copy*[T: Component](c: T): T =
  new result
  deepCopy(result, c)

