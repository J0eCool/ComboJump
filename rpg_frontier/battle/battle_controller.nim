import sequtils

import
  rpg_frontier/[
    animation,
    enemy,
    level,
    player_stats,
    potion,
    skill,
    skill_kind,
    transition,
  ],
  rpg_frontier/battle/[
    battle_entity,
    battle_model,
  ],
  color,
  menu,
  util,
  vec

type
  BattleController* = ref object of Controller
    animation*: AnimationCollection
    bufferClose*: bool

proc newBattleController*(): BattleController =
  BattleController(
    name: "Battle",
    animation: newAnimationCollection(),
  )

proc processAttackDamage*(controller: BattleController, damage: int, target: BattleEntity) =
  target.takeDamage(damage)
  controller.animation.addFloatingText FloatingText(
    text: $damage,
    startPos: target.pos + randomVec(30.0),
  )

proc advanceStage(battle: BattleData, controller: BattleController) =
  if battle.curStageIndex + 1 >= battle.stages.len:
    controller.bufferClose = true
  else:
    battle.curStageIndex += 1
    battle.spawnCurrentStage()

proc killEnemy(battle: BattleData, controller: BattleController, target: BattleEntity) =
  let xpGained = 1
  controller.animation.addFloatingText FloatingText(
    text: "+" & $xpGained & "xp",
    startPos: target.pos + randomVec(5.0),
  )
  battle.stats.addXp(xpGained)
  let dx = random(300.0, 700.0)
  controller.animation.queueEvent(0.8) do (pct: float):
    target.offset = vec(dx * pct, -2200.0 * pct * (0.25 - pct))
  controller.animation.wait(0.1)
  controller.animation.queueEvent do (pct: float):
    battle.enemies.mustRemove(target)
    battle.turnQueue = battle.turnQueue.filterIt(it.entity != target)
    if battle.enemies.len == 0:
      battle.advanceStage(controller)
  controller.animation.wait(0.3)

proc killPlayer(battle: BattleData, controller: BattleController) =
  controller.bufferClose = true

proc updateMaybeKill(battle: BattleData, controller: BattleController, target: BattleEntity) =
  if target.health > 0:
    return

  if target == battle.player:
    battle.killPlayer(controller)
  else:
    battle.killEnemy(controller, target)

proc isClickReady*(battle: BattleData, controller: BattleController): bool =
  controller.animation.notBlocking and battle.activeEntity == battle.player

proc startAttack*(battle: BattleData, controller: BattleController,
                 skill: SkillInfo, attacker, target: BattleEntity) =
  let
    damage = skill.damageFor(attacker)
    targets = skill.toTargets(battle.enemies, target)
  controller.animation.queueEvent(0.1) do (t: float):
    battle.updateAttackAnimation(t)
  controller.animation.queueEvent do (t: float):
    let basePos = target.pos - vec(100)
    controller.animation.addVfx Vfx(
      pos: basePos,
      sprite: "Slash.png",
      scale: 4,
      duration: 0.2,
      update: (proc(vfx: var Vfx, t: float) =
        vfx.pos = basePos + t * vec(200)
      ),
    )
  controller.animation.wait(0.1)
  controller.animation.queueEvent do (t: float):
    for enemy in targets:
      controller.processAttackDamage(damage, enemy)
    controller.animation.queueAsync(0.175) do (t: float):
      battle.updateAttackAnimation(1.0 - t)
  controller.animation.queueEvent do (t: float):
    for enemy in targets:
      battle.updateMaybeKill(controller, enemy)
  controller.animation.wait(0.25)
  controller.animation.queueEvent do (t: float):
    battle.endTurn()

proc tryUseAttack*(battle: BattleData, controller: BattleController, entity: BattleEntity) =
  let skill = battle.selectedSkill
  assert skill != nil
  assert entity != nil
  if battle.canAfford(skill) and
     battle.isClickReady(controller):
    battle.player.mana -= skill.manaCost
    battle.player.focus -= skill.focusCost
    battle.startAttack(controller, skill, battle.player, entity)

proc canUse*(potion: Potion): bool =
  potion.charges > 0 and potion.cooldown == 0

proc tryUsePotion*(battle: BattleData, controller: BattleController, potion: ptr Potion) =
  if not potion[].canUse():
    return
  potion.charges -= 1

  let info = potion.info
  case info.kind
  of healthPotion:
    battle.player.health += info.effect
  of manaPotion:
    battle.player.mana += info.effect

proc clampResources(entity: BattleEntity) =
  entity.health = entity.health.clamp(0, entity.maxHealth)
  entity.mana = entity.mana.clamp(0, entity.maxMana)
  entity.focus = entity.focus.clamp(0, entity.maxFocus)
proc clampResources(battle: BattleData) =
  battle.player.clampResources()
  for enemy in battle.enemies.mitems:
    enemy.clampResources()

proc beginEnemyAttack(battle: BattleData, controller: BattleController) =
  let
    enemy = battle.activeEntity
    skill = allSkills[enemy.knownSkills[0]]
  battle.startAttack(controller, skill, enemy, battle.player)

proc battleUpdate*(battle: BattleData, controller: BattleController, dt: float) =
  if controller.bufferClose:
    controller.shouldPop = true
    controller.bufferClose = false
    return

  controller.animation.update(dt)

  if controller.animation.notBlocking():
    battle.updateTurnQueue(dt)
    if battle.isEnemyTurn:
      battle.beginEnemyAttack(controller)

  battle.clampResources()

method pushMenus(controller: BattleController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]
