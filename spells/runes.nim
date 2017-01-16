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
    wave
    turn
    grow
    moveUp
    moveSide
    nearest
    startPos

  SpellDesc* = seq[Rune]
