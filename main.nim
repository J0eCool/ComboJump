import
  sdl2,
  sdl2.ttf

import
  game,
  program,
  input,
  util,
  vec

let screenSize = vec(1200, 900)
var g = newGame(screenSize)
main(g, screenSize)
