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
  self.id = entity.id()
  self.damage = 0
  self.itemConf = {}
  self.dps = 0
  self.multiplier = 0
  local heldItem = world.entityHandItem(self.id, "primary")
  local heldItem2 = world.entityHandItem(self.id, "alt")
  local twoHanded = false
  if heldItem then
    self.itemConf = root.itemConfig(heldItem)
    twoHanded = self.itemConf.config.twoHanded
  end

  if twoHanded and root.itemHasTag(heldItem, "melee") and not root.itemHasTag(heldItem, "hammer") then
    self.dps = self.itemConf.config.primaryAbility.baseDps
    self.damage = 2*status.stat("powerMultiplier")*self.dps
  else
    self.tag = ""
    if heldItem then 
      if root.itemHasTag(heldItem, "melee") then self.tag = "melee"
      elseif root.itemHasTag(heldItem, "ninja") then self.tag = "ninja" end
    end
    if self.tag == "melee" then
      self.dps = self.itemConf.config.primaryAbility.baseDps
      self.multiplier = 1.5
    elseif self.tag == "ninja" then
      self.dps = self.itemConf.config.projectileConfig.power
      self.multiplier = 1.5
    end
    self.damage = self.dps
    self.tag = ""
    self.dps = 0
    if heldItem2 then
      self.itemConf = root.itemConfig(heldItem2)
      if root.itemHasTag(heldItem2, "melee") then self.tag = "melee"
      elseif root.itemHasTag(heldItem2, "ninja") then self.tag = "ninja" end
    end
    if self.tag == "melee" then
      self.dps = self.itemConf.config.primaryAbility.baseDps
      self.multiplier = self.multiplier == 0 and 1.5 or self.multiplier*1.5
    elseif self.tag == "ninja" then
      self.dps = self.itemConf.config.projectileConfig.power
      self.multiplier = self.multiplier == 0 and 1.5 or self.multiplier*1.5
    end
    self.damage = self.damage + self.dps
    self.damage = self.damage*self.multiplier*status.stat("powerMultiplier")
  end

  self.damageConfig = {
    power = self.damage
  }
  if self.damage > 0 then
    animator.playSound("slash")
    world.spawnProjectile("ninjaassassinateswoosh", {mcontroller.xPosition() + mcontroller.facingDirection()*5, mcontroller.yPosition()}, self.id, {0,0}, false, self.damageConfig)
  end
end

function uninit()
end
