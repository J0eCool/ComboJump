import unittest

import
  input,
  menu

suite "Button":
  setup:
    var
      count = 0
      menus = MenuManager()
    let button = Button(
      onClick: (proc() = count += 1),
      hotkey: jump,
    )

  test "No click on init":
    check count == 0

  test "Hotkey - Pressing activates":
    button.update(menus, inputFromPairs(@[(jump, pressed)]))
    check count == 1

  test "Hotkey - Releasing only activates once":
    button.update(menus, inputFromPairs(@[(jump, pressed)]))
    button.update(menus, inputFromPairs(@[(jump, released)]))
    check count == 1

  test "Hotkey - Holding doesn't activate":
    button.update(menus, inputFromPairs(@[(jump, pressed)]))
    for i in 0..<3:
      button.update(menus, inputFromPairs(@[(jump, held)]))
    check count == 1

  test "Hotkey - Pressing n times activates n times":
    for i in 0..<17:
      button.update(menus, inputFromPairs(@[(jump, pressed)]))
      button.update(menus, inputFromPairs(@[(jump, released)]))
    check count == 17

  test "Hotkey - Pressing wrong key doesn't activate":
    button.update(menus, inputFromPairs(@[(left, pressed)]))
    check count == 0
