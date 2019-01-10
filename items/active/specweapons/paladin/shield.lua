require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.debug = true

  self.aimAngle = 0
  self.aimDirection = 1

  self.active = false
  self.cooldownTimer = config.getParameter("cooldownTime")
  self.activeTimer = 0
  self.pCooldownTimer = config.getParameter("cooldownTime")
  self.beamTimer = 0
  self.perfectShieldBonus = 1
  self.impactSoundTimer = 0

  self.muzzleOffset = config.getParameter("muzzleOffset")
  self.beamLength = config.getParameter("beamLength")
  self.origBeamLength = self.beamLength
  self.damageConfig = config.getParameter("damageConfig")
  self.fireTime = config.getParameter("fireTime")
  self.baseDps = config.getParameter("baseDps")
  self.energyUsage = config.getParameter("energyUsage")
  self.chain = config.getParameter("chain")
  self.beamTransitionFrames = config.getParameter("beamTransitionFrames")
  self.transitionTimer = 0
  self.beamTransitionTime = config.getParameter("beamTransitionTime")

  self.level = config.getParameter("level", 1)
  self.baseShieldHealth = config.getParameter("baseShieldHealth", 1)
  self.knockback = config.getParameter("knockback", 0)
  self.perfectBlockDirectives = config.getParameter("perfectBlockDirectives", "")
  self.perfectBlockTime = config.getParameter("perfectBlockTime", 0.2)
  self.minActiveTime = config.getParameter("minActiveTime", 0)
  self.cooldownTime = config.getParameter("cooldownTime")
  self.pCooldownTime = config.getParameter("primaryCooldownTime")
  self.forceWalk = config.getParameter("forceWalk", false)

  self.beamActive = false
  self.fireMode = "none"
  self.raised = false

  self.shieldPoly = animator.partPoly("shield", "shieldPoly")
  self.knockbackDamageSource = {
    poly = self.shieldPoly,
    damage = 0,
    damageType = "Knockback",
    sourceEntity = activeItem.ownerEntityId(),
    team = activeItem.ownerTeam(),
    knockback = self.knockback*1.5,
    rayCheck = true,
    damageRepeatTimeout = 0.25
  }

  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  activeItem.setOutsideOfHand(true)

  self.stances = config.getParameter("stances")
  setStance(self.stances.idle)
  animator.setSoundVolume("fireStart", 0.5, 0)
  animator.setSoundVolume("fireEnd", 0.5, 0)

  updateAim()
end

function update(dt, fireMode, shiftHeld)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.pCooldownTimer = math.max(0, self.pCooldownTimer - dt)
  self.impactSoundTimer = math.max(0, self.impactSoundTimer - dt)
  self.beamTimer = math.max(0, self.beamTimer - dt)
  self.fireMode = fireMode
  self.dt = dt

  if self.cooldownTimer == 0 and status.resourcePositive("shieldStamina") then
    if fireMode == "primary" and self.pCooldownTimer == 0 and not self.beamActive and not status.resourceLocked("energy") then
      chargeBeam()
    elseif fireMode == "alt" and not self.active then
      raiseShield()
    elseif fireMode == "alt" and self.beamActive and self.beamTimer < 1.5 then
      self.beamTimer = math.min(self.beamTimer, 0.25)
    end
  end

  if self.pCooldownTimer == 0 and self.beamTimer == 0 then
    if self.active then
      animator.setAnimationState("auraLoop", "aura_raised")
    else
      animator.setAnimationState("auraLoop", "aura")
    end
  elseif self.beamTimer == 0 then
    animator.setAnimationState("auraLoop", "idle")
  end

  if self.active then
    self.activeTimer = self.activeTimer + dt

    self.damageListener:update()

    if status.resourcePositive("perfectBlock") then
      animator.setGlobalTag("directives", self.perfectBlockDirectives)
    else
      animator.setGlobalTag("directives", "")
    end

    if self.forceWalk then
      mcontroller.controlModifiers({runningSuppressed = true})
    end

    if (fireMode ~= "alt" and self.activeTimer >= self.minActiveTime and self.beamTimer == 0) or not status.resourcePositive("shieldStamina") then
      lowerShield()
    end
  end

  if self.beamTimer > 0 then
    if self.raised and not self.beamActive then
      fireBeam()
    elseif self.beamActive and self.active and status.overConsumeResource("energy", self.energyUsage * dt) and self.beamTimer > 0.25 then
      self.transitionTimer = math.min(self.transitionTimer + self.dt, self.beamTransitionTime)
      fire()
    else
      cooldown()
    end
  end

  self.beamLength = math.min(self.origBeamLength + (self.perfectShieldBonus - 1) * 5, 35)

  if status.resourceLocked("energy") then
    self.beamTimer = math.min(self.beamTimer, 0.25)
  end

  if self.beamActive and ((not self.active or not self.raised) or self.beamTimer == 0) then
    endBeam()
  end

  updateAim()

  incorrectWeapon()
end

function uninit()
  status.clearPersistentEffects(activeItem.hand().."Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
  reset()
  incorrectWeapon(true)
end

function updateAim()
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  self.aimAngle = 0
  
  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  if self.stance.allowFlip then
    self.aimDirection = aimDirection
  end
  activeItem.setFacingDirection(self.aimDirection)

  animator.setGlobalTag("hand", isNearHand() and "near" or "far")
  activeItem.setTwoHandedGrip(self.active)
end

function isNearHand()
  return (activeItem.hand() == "primary") == (self.aimDirection < 0)
end

function setStance(stance)
  self.stance = stance
  self.relativeShieldRotation = util.toRadians(stance.shieldRotation) or 0
  self.relativeArmRotation = util.toRadians(stance.armRotation) or 0
end

function raiseShield()
  setStance(self.stances.raised)
  animator.setAnimationState("shield", "raised")
  animator.setAnimationState("auraLoop", "idle")
  animator.playSound("raiseShield")
  self.active = true
  self.activeTimer = 0
  status.setPersistentEffects(activeItem.hand().."Shield", {{stat = "shieldHealth", amount = shieldHealth()}})
  activeItem.setItemShieldPolys({self.shieldPoly})

  activeItem.setItemDamageSources({ self.knockbackDamageSource })

  self.damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          animator.playSound("perfectBlock")
          animator.burstParticleEmitter("perfectBlock")
          self.perfectShieldBonus = math.min(self.perfectShieldBonus + 0.25, 5)
          status.addEphemeralEffect("regeneration4", 2 + (self.perfectShieldBonus / 2.5))
          refreshPerfectBlock()
        elseif status.resourcePositive("shieldStamina") then
          animator.playSound("block")
          if not self.beamActive then self.perfectShieldBonus = math.max(self.perfectShieldBonus - 0.25, 1) end
        else
          self.perfectShieldBonus = 1
          animator.playSound("break")
        end
        animator.setAnimationState("shield", "block")
        return
      end
    end
  end)

  refreshPerfectBlock()
  self.raised = true
end

function refreshPerfectBlock()
  local perfectBlockTimeAdded = math.max(0, math.min(status.resource("perfectBlockLimit"), self.perfectBlockTime - status.resource("perfectBlock")))
  status.overConsumeResource("perfectBlockLimit", perfectBlockTimeAdded)
  status.modifyResource("perfectBlock", perfectBlockTimeAdded)
end

function lowerShield()
  setStance(self.stances.idle)
  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  animator.setAnimationState("auraLoop", "idle")
  animator.playSound("lowerShield")
  self.active = false
  self.activeTimer = 0
  status.clearPersistentEffects(activeItem.hand().."Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
  self.cooldownTimer = self.cooldownTime
  self.raised = false
end

function shieldHealth()
  return self.baseShieldHealth * root.evalFunction("shieldLevelMultiplier", self.level)
end

function chargeBeam()
  if not self.active then
    raiseShield()
  end
  if not world.lineTileCollision(mcontroller.position(), firePosition()) then
    self.beamTimer = 2.0
    self.transitionTimer = 0
  end
end

function fireBeam()
  self.beamActive = true
  animator.setAnimationState("auraLoop", "idle")
  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)
end

function fire()
  local wasColliding = false
  
  local beamStart = firePosition()
  local beamEnd = vec2.add(beamStart, vec2.mul(aimVector(), self.beamLength))
  local beamLength = self.beamLength

  local collidePoint = world.lineCollision(beamStart, beamEnd)
  if collidePoint then
    beamEnd = collidePoint

    beamLength = world.magnitude(beamStart, beamEnd)
    --Needed for some reason to make it look nicer.
    beamLength = (beamLength + 1) * (1.20 - beamLength/100.0)

    animator.setParticleEmitterActive("beamCollision", true)
    animator.resetTransformationGroup("beamEnd")
    animator.translateTransformationGroup("beamEnd", {beamLength, 0})

    if self.impactSoundTimer == 0 then
      animator.setSoundPosition("beamImpact", {beamLength, 0})
      animator.playSound("beamImpact")
      self.impactSoundTimer = self.fireTime
    end
  else
    animator.setParticleEmitterActive("beamCollision", false)
  end

  setDamage(self.damageConfig, {{self.muzzleOffset[1], self.muzzleOffset[2]}, {self.muzzleOffset[1] + beamLength, self.muzzleOffset[2]}}, self.fireTime)
  animator.setLightActive("gold", true)
  drawBeam(beamEnd, collidePoint)
end

function endBeam()
  reset()
  animator.setParticleEmitterActive("beamCollision", false)
  animator.playSound("fireEnd")
  self.beamActive = false
  self.beamTimer = 0
  self.pCooldownTimer = self.pCooldownTime
  animator.setLightActive("gold", false)
end

function setDamage(damageConfig, damageArea, damageTimeout)
  activeItem.setItemDamageSources({self.knockbackDamageSource, damageSource(damageConfig, damageArea, damageTimeout)})
end

function damageSource(damageConfig, damageArea, damageTimeout)
  if damageArea then
    local knockback = damageConfig.knockback
    if knockback and damageConfig.knockbackDirectional ~= false then
      knockback = knockbackMomentum(damageConfig.knockback, damageConfig.knockbackMode, 0, mcontroller.facingDirection())
    end
    local damage = self.baseDps * activeItem.ownerPowerMultiplier() * self.perfectShieldBonus
    --if knockback then knockback = knockback * (1 + self.perfectShieldBonus / 10) end

    local damageLine, damagePoly
    if #damageArea == 2 then
      damageLine = damageArea
    else
      damagePoly = damageArea
    end

    return {
      poly = damagePoly,
      line = damageLine,
      damage = damage,
      trackSourceEntity = damageConfig.trackSourceEntity,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = damageConfig.damageSourceKind,
      statusEffects = damageConfig.statusEffects,
      knockback = knockback or 0,
      rayCheck = true,
      damageRepeatGroup = damageRepeatGroup(damageConfig.timeoutGroup),
      damageRepeatTimeout = damageTimeout or damageConfig.timeout
    }
  end
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.muzzleOffset))
end

function aimVector()
  --local aimVector = {mcontroller.facingDirection(), 0}
  local aimVector = vec2.rotate({1, 0}, self.aimAngle)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function drawBeam(endPos, didCollide)
  local newChain = copy(self.chain)
  newChain.startOffset = self.muzzleOffset
  newChain.endPosition = endPos

  if didCollide then
    newChain.endSegmentImage = nil
  end

  local currentFrame = beamFrame()
  if newChain.startSegmentImage then
    newChain.startSegmentImage = newChain.startSegmentImage:gsub("<beamFrame>", currentFrame)
  end
  newChain.segmentImage = newChain.segmentImage:gsub("<beamFrame>", currentFrame)
  if newChain.endSegmentImage then
    newChain.endSegmentImage = newChain.endSegmentImage:gsub("<beamFrame>", currentFrame)
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function beamFrame()
  return math.max(1, math.min(self.beamTransitionFrames, math.floor(self.transitionTimer * self.beamTransitionFrames / self.beamTransitionTime + 1.25)))
end

function cooldown()
  if self.transitionTimer > 0 then
    self.transitionTimer = math.max(0, self.transitionTimer - self.dt)

    if self.transitionTimer == 0 then
      activeItem.setScriptedAnimationParameter("chains", {})
    else
      local beamStart = firePosition()
      local beamEnd = vec2.add(beamStart, vec2.mul(aimVector(), self.beamLength))
      local collidePoint = world.lineCollision(beamStart, beamEnd)
      if collidePoint then
        beamEnd = collidePoint
      end

      drawBeam(beamEnd, collidePoint)
    end
  end
end

function knockbackMomentum(knockback, knockbackMode, aimAngle, aimDirection)
  knockbackMode = knockbackMode or "aim"

  if type(knockback) == "table" then
    return knockback
  end

  if knockbackMode == "facing" then
    return {aimDirection * knockback, 0}
  elseif knockbackMode == "aim" then
    local aimVector = vec2.rotate({knockback, 0}, aimAngle)
    aimVector[1] = aimDirection * aimVector[1]
    return aimVector
  end
  return knockback
end

function damageRepeatGroup(mode)
  mode = mode or ""
  return activeItem.ownerEntityId() .. config.getParameter("itemName") .. activeItem.hand() .. mode
end

function reset()
  activeItem.setItemDamageSources(self.raised and {self.knockbackDamageSource} or {})
  activeItem.setScriptedAnimationParameter("chains", {})
  --animator.setParticleEmitterActive("beamCollision", false)
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
end