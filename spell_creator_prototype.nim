import sdl2

import
  component/[
    sprite,
    transform,
  ],
  system/[
    render,
  ],
  camera,
  entity,
  event,
  game,
  game_system,
  program,
  vec

type SpellCreatorPrototype = ref object of Game

type Rotator = ref object of Component
  speed: float

proc updateRotators(entities: Entities, dt: float) =
  entities.forComponents entity, [
    Rotator, rotator,
    Sprite, sprite,
  ]:
    sprite.angle += rotator.speed * dt

proc newSpellCreatorPrototype(screenSize: Vec): SpellCreatorPrototype =
  new result
  result.camera.screenSize = screenSize
  result.title = "Spell Creator (prototype)"

method loadEntities(spellCreator: SpellCreatorPrototype) =
  spellCreator.entities = @[
    newEntity("Test", [
      Transform(pos: vec(400, 400), size: vec(60, 60)),
      Sprite(textureName: "Goblin.png"),
      Rotator(speed: 60.0),
    ]),
  ]

method update*(spellCreator: SpellCreatorPrototype, dt: float) =
  updateRotators(spellCreator.entities, dt)

method draw*(renderer: RendererPtr, spellCreator: SpellCreatorPrototype) =
  renderer.drawGame(spellCreator)

  renderer.renderSystem(spellCreator.entities, spellCreator.camera)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newSpellCreatorPrototype(screenSize), screenSize)
