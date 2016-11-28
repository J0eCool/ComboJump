import
  sdl2

import
  component/sprite,
  camera,
  drawing,
  entity,
  event,
  rect,
  resources,
  system,
  util,
  vec

type
  DecorationInfo = ref object
    filename: string
    size: Vec
    sprite: SpriteData
  Decoration = object
    info: DecorationInfo
    pos: Vec
  ScrollingBackground* = object
    decos: seq[Decoration]
    infos: seq[DecorationInfo]
    speed: float
    loaded: bool
    spawnDist: float
    distMoved: float
    spawnedUpTo: float

proc newScrollingBackground*(speed: float): ScrollingBackground =
  result = ScrollingBackground(
    decos: @[],
    infos: @[
      DecorationInfo(filename: "GrassTuft.png",
                     size: vec(12, 8)),
      DecorationInfo(filename: "GrassTuft2.png",
                     size: vec(28, 12)),
    ],
    speed: speed,
    spawnDist: 5.0,
  )

proc loadBackgroundAssets*(
    background: var ScrollingBackground,
    resources: var ResourceManager,
    renderer: RendererPtr) =
  if not background.loaded:
    for info in background.infos.mitems:
      info.sprite = resources.loadSprite(info.filename, renderer)
    background.loaded = true

proc draw*(renderer: RendererPtr, background: ScrollingBackground, camera: Camera) =
  renderer.setDrawColor color(67, 167, 81, 255)
  renderer.fillRect rect.rect(camera.screenSize / 2, camera.screenSize)

  for deco in background.decos:
    let
      info = deco.info
      r = rect.rect(deco.pos + vec(0.0, background.distMoved), info.size)
    renderer.draw info.sprite, r

defineSystem:
  proc update*(background: var ScrollingBackground, dt: float, camera: Camera) =
    background.distMoved += background.speed * dt
    while background.spawnedUpTo < background.distMoved + camera.screenSize.y:
      let
        dist = background.spawnDist
        spawnPos = vec(random(0.0, camera.screenSize.x), -background.spawnedUpTo + camera.screenSize.y)
        info = random(background.infos)
      background.decos.add Decoration(info: info, pos: spawnPos)
      background.spawnedUpTo += dist
