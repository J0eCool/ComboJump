from sdl2 import RendererPtr

import
  component/[
    transform,
  ],
  camera,
  color,
  drawing,
  entity,
  event,
  game_system,
  rect,
  resources,
  vec

type
  Particle = object
    pos: Vec
    vel: Vec
  ParticleEffectObj* = object of ComponentObj
    color*: Color
    particles: seq[Particle]
  ParticleEffect* = ref object of ParticleEffectObj

defineComponent(ParticleEffect, @[
  "particles",
])

defineSystem:
  components = [ParticleEffect]
  proc updateParticleEffect*(dt: float) =
    if particleEffect.particles == nil:
      particleEffect.particles = @[]
      for i in 0..<6:
        particleEffect.particles.add Particle(
          pos: vec(),
          vel: randomVec(300, 600),
        )

    for particle in particleEffect.particles.mitems:
      particle.pos += particle.vel * dt

defineDrawSystem:
  priority = -50
  components = [ParticleEffect, Transform]
  proc drawParticleEffect*(resources: ResourceManager, camera: Camera) =
    for particle in particleEffect.particles:
      let r = rect(particle.pos + transform.globalPos + camera.offset, vec(12))
      renderer.fillRect(r, particleEffect.color)
