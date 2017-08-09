function init()
  self.timer = 0
  animator.setAnimationState("blink", "blinkout")
  effect.setParentDirectives("?multiply=ffffff00")
  animator.playSound("activate")
  effect.addStatModifierGroup({{stat = "activeMovementAbilities", amount = 1}})
  mcontroller.setVelocity({0,0})
  mcontroller.controlModifiers({
    speedModifier = 0,
    airJumpModifier = 0
  })
end

function update(dt)
  mcontroller.setVelocity({0,0})
  mcontroller.controlModifiers({
    speedModifier = 0,
    airJumpModifier = 0
  })
  if animator.animationState("blink") == "none" then
    teleport()
  end
end

function teleport()
  mcontroller.setVelocity({0,0})
  mcontroller.controlModifiers({
    speedModifier = 0,
    airJumpModifier = 0
  })
  local discId = status.statusProperty("translocatorDiscId")
  if discId and world.entityExists(discId) then
    local teleportTarget = world.callScriptedEntity(discId, "teleportPosition", mcontroller.collisionPoly())
    if teleportTarget then
      mcontroller.setPosition(teleportTarget)
    end
    world.callScriptedEntity(status.statusProperty("translocatorDiscId"), "kill")
  end
  status.setStatusProperty("translocatorDiscId", nil)

  effect.setParentDirectives("")
  animator.burstParticleEmitter("translocate")
  animator.setAnimationState("blink", "blinkin")
  self.damageConfig = {
    power = world.entityCurrency(entity.id(), "dexteritypoint")
  }
  animator.playSound("slash")
  world.spawnProjectile("ninjaassassinateswoosh", {mcontroller.xPosition() + mcontroller.facingDirection()*5, mcontroller.yPosition()}, entity.id(), {0,0}, false, self.damageConfig)
end

function uninit()
end
