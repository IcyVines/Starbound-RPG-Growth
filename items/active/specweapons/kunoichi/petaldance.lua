require "/scripts/ivrpgutil.lua"

-- Melee primary ability
MeleeSlash = WeaponAbility:new()

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  animator.setGlobalTag("directives", "")
  animator.setGlobalTag("bladeDirectives", "")

  self.weapon = Weapon:new()
  self.damageModifier = config.getParameter("primaryAbility.damageModifier", 1)

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAttack = getAltAbility()
  if secondaryAttack then
    self.weapon:addAbility(secondaryAttack)
  end

  self.weapon:init()
  self.hand = activeItem.hand()
  self.active = false
  self.combo = 0
end

function MeleeSlash:init()
  self.hand = activeItem.hand()

  self.damageConfig.baseDamage = self.baseDps * self.fireTime
  self.combo = 0

  self.energyUsage = self.energyUsage or 0

  self.comboDirectionSet = "normal"
  if self.active then
    self.weapon:setStance(self.stances["readyIdle" .. self.hand])
  else
    self.weapon:setStance(self.stances.idle)
  end

  self.cooldownTimer = self:cooldownTime()
  self.backwardTimer = 0

  self.weapon.onLeaveAbility = function()
    if self.active then
      self.weapon:setStance(self.stances["readyIdle" .. self.hand])
    else
      self.weapon:setStance(self.stances.idle)
    end
  end
end

-- Ticks on every update regardless if this is the active ability
function MeleeSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  incorrectWeapon()

  if not self.active then animator.setAnimationState("blade", "closed" .. self.hand) end

  self.comboDirection = shiftHeld and "normal" or ((not mcontroller.onGround()) and "aerial" or (mcontroller.crouching() and "downward" or (not mcontroller.running() and "normal" or ((mcontroller.facingDirection() == mcontroller.movingDirection() and mcontroller.running()) and "forward" or "backward"))))

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.backwardTimer = math.max(0, self.backwardTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
      self.comboDirectionSet = not self.active and "opening" or self.comboDirection
      if (self.comboDirectionSet == "downward" or self.comboDirectionSet == "aerial") and not status.statPositive("ivrpgwluxuriadownsmash") and not status.statPositive("activeMovementAbilities") then
        self:setState(self.slash)
      else
        self:setState(self.windup)
      end
  end
end

function duplicateTable(old)
  local new = {}
  for k,v in pairs(old) do
    new[k] = v
  end
  return new
end

-- State: windup
function MeleeSlash:windup()
  if (self.comboDirectionSet == "downward") or (self.backwardTimer > 0 and self.comboDirectionSet == "backward") then self.comboDirectionSet = "normal" end
  local stance = duplicateTable(self.stances.windup[self.comboDirectionSet])
  local hand = (self.combo % 2 == 1 and self.hand == "primary") and "alt" or ((self.combo % 2 == 1 and self.hand == "alt") and "primary" or self.hand)

  if stance[hand] then
    for k,v in pairs(stance[hand]) do
      stance[k] = v
    end
  end

  self.weapon:setStance(stance)

  if self.comboDirectionSet == "forward" then
    status.setPersistentEffects("ivrpgLuxuriaWeaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  end

  if stance.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  else
    util.wait(stance.duration / (math.min(self.combo + 1, 4)), function(dt)
      if self.comboDirectionSet == "backward" then
        mcontroller.controlModifiers({
          jumpingSuppressed = true,
          movementSuppressed = true
        })
        mcontroller.controlCrouch()
      elseif self.comboDirectionSet == "forward" then
        mcontroller.controlModifiers({
          jumpingSuppressed = true,
          movementSuppressed = true
        })
      end
    end)
  end

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.stances.preslash then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

-- State: preslash
-- brief frame in between windup and fire
function MeleeSlash:preslash()
  self.weapon:setStance(self.stances.preslash)
  self.weapon:updateAim()

  util.wait(self.stances.preslash.duration)

  self:setState(self.fire)
end

-- State: fire
function MeleeSlash:fire()
  local stance = duplicateTable(self.stances.fire[self.comboDirectionSet])
  local hand = (self.combo % 2 == 1 and self.hand == "primary") and "alt" or ((self.combo % 2 == 1 and self.hand == "alt") and "primary" or self.hand)
  if stance[hand] then
    for k,v in pairs(stance[hand]) do
      stance[k] = v
    end
  end

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local damageConfig = duplicateTable(self.damageConfig)
  if stance.damageConfig then
    for k,v in pairs(stance.damageConfig) do
      if k == "baseDamage" then
        v = v * math.min(((self.combo + 2)/4), 1.5)
      end
      damageConfig[k] = v * self.damageModifier
    end
  end

  animator.burstParticleEmitter((self.elementalType or self.weapon.elementalType) .. "swoosh")
  animator.playSound(stance.fireSound or "fire")
  animator.setAnimationState("swoosh", "fire" .. self.hand)

  local facingDirection = mcontroller.facingDirection()
  if self.comboDirectionSet == "backward" then
    -- Backwards Slash + Flower Explosion
    self.weapon.aimDirection = -self.weapon.aimDirection
    self.weapon:updateAim()
    
    if status.overConsumeResource("energy", stance.energyUsage) then
      local position = vec2.add(mcontroller.position(), {stance.projectileOffset[1] * mcontroller.facingDirection(), stance.projectileOffset[2]})
      local projectileParams = {
        powerMultiplier = activeItem.ownerPowerMultiplier(),
        power = damageConfig.baseDamage * stance.projectilePowerMultiplier,
        knockback = damageConfig.knockback * stance.projectileKnockbackMultiplier
      }
      world.spawnProjectile(stance.projectileType .. self.hand, position, activeItem.ownerEntityId(), {mcontroller.facingDirection(), 0}, false, projectileParams)
    end
  elseif self.comboDirectionSet == "normal" then
    -- Flying Swoosh
    if status.overConsumeResource("energy", stance.energyUsage) then
      local position = vec2.add(mcontroller.position(), {stance.projectileOffset[1] * mcontroller.facingDirection(), stance.projectileOffset[2]})
      local projectileParams = {
        powerMultiplier = activeItem.ownerPowerMultiplier(),
        power = damageConfig.baseDamage * stance.projectilePowerMultiplier,
        knockback = damageConfig.knockback * stance.projectileKnockbackMultiplier
      }
      world.spawnProjectile(stance.projectileType .. self.hand, position, activeItem.ownerEntityId(), {mcontroller.facingDirection(), 0}, false, projectileParams)
    end
  elseif self.comboDirectionSet == "aerial" then
    -- Downward Flying Swoosh
    if status.overConsumeResource("energy", stance.energyUsage) then
      local position = vec2.add(mcontroller.position(), {stance.projectileOffset[1] * mcontroller.facingDirection(), stance.projectileOffset[2]})
      local projectileParams = {
        powerMultiplier = activeItem.ownerPowerMultiplier(),
        power = damageConfig.baseDamage * stance.projectilePowerMultiplier,
        knockback = damageConfig.knockback * stance.projectileKnockbackMultiplier
      }
      world.spawnProjectile(stance.projectileType .. self.hand, position, activeItem.ownerEntityId(), {0, -1}, false, projectileParams)
    end
    mcontroller.controlForce({0, stance.speed})
  elseif self.comboDirectionSet == "forward" then
    -- Travel Slash
    animator.playSound("travelSlash")
    status.addPersistentEffects("ivrpgwluxuriainvulnerable", {{stat = "invulnerable", amount = 1}})
    local position = mcontroller.position()
  end

  util.wait(stance.duration, function()
    if self.comboDirectionSet == "forward" then
      mcontroller.setVelocity({self.weapon.aimDirection * stance.dashSpeed, -200})
      mcontroller.controlMove(self.weapon.aimDirection)
    elseif self.comboDirectionSet == "backward" then
      mcontroller.controlModifiers({
        movementSuppressed = true
      })
    elseif self.comboDirectionSet == "opening" then
      animator.setAnimationState("blade", "open" .. self.hand)
      self.active = true
    else
      --normal/default
    end

    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(damageConfig, damageArea, self.fireTime)

  end)

  if self.comboDirectionSet == "backward" then
    -- Backwards Slash + Flower Explosion
    self.weapon.aimDirection = -self.weapon.aimDirection
    self.weapon:updateAim()
    self.backwardTimer = stance.cooldown
  elseif self.comboDirectionSet == "forward" then
    status.clearPersistentEffects("ivrpgLuxuriaWeaponMovementAbility")
    status.clearPersistentEffects("ivrpgwluxuriainvulnerable")
  end

  if self.stances.winddown[self.comboDirectionSet] then
    self:setState(self.winddown)
    return
  end

  self.cooldownTimer = self:cooldownTime()

end


function MeleeSlash:winddown()
  local stance = duplicateTable(self.stances.winddown[self.comboDirectionSet])
  local hand = (self.combo % 2 == 1 and self.hand == "primary") and "alt" or ((self.combo % 2 == 1 and self.hand == "alt") and "primary" or self.hand)
  if stance[hand] then
    for k,v in pairs(stance[hand]) do
      stance[k] = v
    end
  end

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  util.wait(stance.duration)

  if self.fireMode == "primary" and not status.statPositive("ivrpgwluxuriadownsmash") then
    self.combo = self.combo + 1
    if self.shiftHeld then
      self.comboDirectionSet = "normal"
    elseif mcontroller.crouching() then
      self.comboDirectionSet = "downward"
      self:setState(self.slash)
      return
    elseif math.abs(mcontroller.xVelocity()) > 0.5 and mcontroller.movingDirection() ~= mcontroller.facingDirection() and self.comboDirectionSet ~= "backward" then
      self.comboDirectionSet = "backward"
    elseif math.abs(mcontroller.xVelocity()) > 0.5 and mcontroller.movingDirection() == mcontroller.facingDirection() and self.comboDirectionSet ~= "forward" then
      self.comboDirectionSet = "forward"
    else
      self.comboDirectionSet = "normal"
    end
    self:setState(self.windup)
  else
    self.combo = 0
    self.cooldownTimer = self:cooldownTime()
  end
  
end

function MeleeSlash:slash()
  status.setPersistentEffects("ivrpgwluxuriadownsmash", {{stat = "ivrpgwluxuriadownsmash", amount = 1}})
  local slash = coroutine.create(self.slashAction)
  local stance = self.stances.slash[self.comboDirectionSet .. "Slash"]
  coroutine.resume(slash, self)

  local movement = function()
    mcontroller.controlModifiers({
      runningSuppressed = true,
      walkingSuppressed = true
    })
    if stance.hover then
      mcontroller.controlApproachYVelocity(stance.hoverYSpeed, stance.hoverForce)
    end
  end

  while util.parallel(slash, movement) do
    coroutine.yield()
  end
end

function MeleeSlash:slashAction()
  local armRotationOffset = math.random(1, #self.armRotationOffsets)
  local windupStance = duplicateTable(self.stances.slash[self.comboDirectionSet .. "Windup"])
  local fireStance = duplicateTable(self.stances.slash[self.comboDirectionSet .. "Slash"])

  local hand = self.hand
  if fireStance[hand] then
    for k,v in pairs(fireStance[hand]) do
      fireStance[k] = v
    end
  end
  if windupStance[hand] then
    for k,v in pairs(windupStance[hand]) do
      windupStance[k] = v
    end
  end

  local damageConfig = duplicateTable(self.damageConfig)
  if fireStance.damageConfig then
    for k,v in pairs(fireStance.damageConfig) do
      damageConfig[k] = v * self.damageModifier
    end
  end

  while self.fireMode == "primary" and (self.comboDirection == "downward" or self.comboDirection == "aerial") do
    if not status.overConsumeResource("energy", fireStance.energyUsage * (windupStance.duration + fireStance.duration)) then
      status.clearPersistentEffects("ivrpgwluxuriadownsmash")
      return
    end
    self.weapon:setStance(windupStance)
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation - util.toRadians(self.armRotationOffsets[armRotationOffset])
    self.weapon:updateAim()

    util.wait(windupStance.duration, function()
      return status.resourceLocked("energy")
    end)

    self.weapon.aimDirection = -self.weapon.aimDirection

    self.weapon:setStance(fireStance)
    self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(self.armRotationOffsets[armRotationOffset])
    self.weapon:updateAim()

    armRotationOffset = armRotationOffset + 1
    if armRotationOffset > #self.armRotationOffsets then armRotationOffset = 1 end

    animator.setAnimationState("spinSwoosh", "fire" .. self.comboDirectionSet .. self.hand, true)
    if fireStance.fireSound then
      animator.playSound(fireStance.fireSound)
    end

    util.wait(fireStance.duration, function()
      local damageArea = partDamageArea("spinSwoosh")
      self.weapon:setDamage(damageConfig, damageArea)
    end)
  end
  self.cooldownTimer = fireStance.duration
  status.clearPersistentEffects("ivrpgwluxuriadownsmash")
end

function MeleeSlash:cooldownTime(comboDirection)
  return self.fireTime - self.stances.windup[self.comboDirectionSet].duration - self.stances.fire[self.comboDirectionSet].duration
end

function MeleeSlash:uninit()
  self.combo = 0
  animator.setGlobalTag("swooshDirectives", "")
  self.weapon:setDamage()
end

function MeleeSlash:faceVector(vector)
  return {vector[1] * mcontroller.facingDirection(), vector[2]}
end

function uninit()
  status.clearPersistentEffects("ivrpgwluxuriadownsmash")
  status.clearPersistentEffects("ivrpgLuxuriaWeaponMovementAbility")
  status.clearPersistentEffects("ivrpgwluxuriainvulnerable")
  self.weapon:uninit()
  incorrectWeapon(true)
end

function Weapon:updateAim()
  self.scale = config.getParameter("scale", {1,1})
  for _,group in pairs(self.transformationGroups) do
    animator.resetTransformationGroup(group.name)
    animator.translateTransformationGroup(group.name, group.offset)
    animator.rotateTransformationGroup(group.name, group.rotation, group.rotationCenter)
    animator.translateTransformationGroup(group.name, self.weaponOffset)
    animator.rotateTransformationGroup(group.name, self.relativeWeaponRotation, self.relativeWeaponRotationCenter)
    animator.scaleTransformationGroup(group.name, self.scale)
  end

  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.aimOffset, activeItem.ownerAimPosition())

  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  elseif self.stance.aimAngle then
    self.aimAngle = self.stance.aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  local isPrimary = activeItem.hand() == "primary"
  if isPrimary then
    -- primary hand weapons should set their aim direction whenever they can be flipped,
    -- unless paired with an alt hand that CAN'T flip, in which case they should use that
    -- weapon's aim direction
    if self.stance.allowFlip then
      if activeItem.callOtherHandScript("dwDisallowFlip") then
        local altAimDirection = activeItem.callOtherHandScript("dwAimDirection")
        if altAimDirection then
          self.aimDirection = altAimDirection
        end
      else
        self.aimDirection = aimDirection
      end
    end
  elseif self.stance.allowFlip then
    -- alt hand weapons should be slaved to the primary whenever they can be flipped
    local primaryAimDirection = activeItem.callOtherHandScript("dwAimDirection")
    if primaryAimDirection then
      self.aimDirection = primaryAimDirection
    else
      self.aimDirection = aimDirection
    end
  end

  activeItem.setFacingDirection(self.aimDirection)

  activeItem.setFrontArmFrame(self.stance.frontArmFrame)
  activeItem.setBackArmFrame(self.stance.backArmFrame)
end