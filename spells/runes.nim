type
  Rune* = enum
    num
    count
    mult
    createSingle
    createSpread
    createBurst
    createRepeat
    despawn

    # update-only runes
    wave
    turn
    grow
    moveUp
    moveSide
    nearest
    startPos

  SpellDesc* = seq[Rune]
