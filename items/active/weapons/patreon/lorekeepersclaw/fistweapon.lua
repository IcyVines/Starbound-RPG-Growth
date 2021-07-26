require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
--require "/scripts/ivrpgutil.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/activeitem/stances.lua"
require "/items/active/weapons/fist/punch.lua"

function init()
  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)

  self.primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(self.primaryAbility)

  local comboFinisherConfig = config.getParameter("comboFinisher")
  self.comboFinisher = getAbility("comboFinisher", comboFinisherConfig)
  self.weapon:addAbility(self.comboFinisher)

  self.weapon:init()
  --initStances()

  self.needsEdgeTrigger = config.getParameter("needsEdgeTrigger", false)
  self.edgeTriggerGrace = config.getParameter("edgeTriggerGrace", 0)
  self.edgeTriggerTimer = 0
  
  self.comboStep = 0
  self.comboSteps = config.getParameter("comboSteps")
  self.comboTiming = config.getParameter("comboTiming")
  self.comboCooldown = config.getParameter("comboCooldown")

  self.weapon.freezeLimit = config.getParameter("freezeLimit", 2)
  self.weapon.freezesLeft = self.weapon.freezeLimit

  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters")
  self.projectileParameters.power = self.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))

  storage.projectileIds = storage.projectileIds or {false, false, false}
  checkProjectiles()

  self.orbitRate = config.getParameter("orbitRate", 1) * -2 * math.pi

  animator.resetTransformationGroup("orbs")
  for i = 1, 3 do
    animator.setAnimationState("orb"..i, storage.projectileIds[i] == false and (self.weapon:isFrontHand() and "orbF" or "orbB") or "hidden")
  end
  setOrbPosition(1)

  self.primaryAbility.shieldActive = false
  self.shieldTransformTimer = 0
  self.shieldTransformTime = config.getParameter("shieldTransformTime", 0.2)
  self.shieldTimer = 0
  self.shieldTime = config.getParameter("shieldTime", 0.3)
  self.primaryAbility.shieldPoly = animator.partPoly("weapon", "shieldPoly")
  self.primaryAbility.shieldEnergyCost = config.getParameter("shieldEnergyCost", 50)
  self.primaryAbility.shieldHealth = 1000
  self.primaryAbility.shieldKnockback = config.getParameter("shieldKnockback", 0)
  if self.primaryAbility.shieldKnockback > 0 then
    self.primaryAbility.knockbackDamageSource = {
      poly = self.primaryAbility.shieldPoly,
      damage = 0,
      damageType = "Knockback",
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      knockback = self.primaryAbility.shieldKnockback,
      rayCheck = true,
      damageRepeatTimeout = 0.5
    }
  end

  --setStance("idle")
  updateHand()
end

function initStances()
  self.stances = config.getParameter("primaryAbility.stances")
  self.fireOffset = config.getParameter("fireOffset", {0, 0})
  self.fireAngleOffset = util.toRadians(config.getParameter("fireAngleOffset", 0))
  self.aimAngle = 0
end

function update(dt, fireMode, shiftHeld)

  --updateStance(dt)
  checkProjectiles()

  if mcontroller.onGround() then
    self.weapon.freezesLeft = self.weapon.freezeLimit
  end

  if self.comboStep > 0 then
    self.comboTimer = self.comboTimer + dt
    if self.comboTimer > self.comboTiming[2] then
      resetFistCombo()
    end
  end

  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  if self.lastFireMode ~= "primary" and fireMode == "primary" then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode

  if fireMode == "primary" and (not self.needsEdgeTrigger or self.edgeTriggerTimer > 0) then
    if self.comboStep > 0 then
      if self.comboTimer >= self.comboTiming[1] then
        if self.comboStep % 2 == 0 then
          if self.primaryAbility:canStartAttack() then
            if self.comboStep == self.comboSteps then
              -- sb.logInfo("[%s] %s fist starting a combo finisher", os.clock(), activeItem.hand())
              startFinisher()
              self.comboFinisher:startAttack()
              --self.comboFinisher:startAttack()
            else
              self.primaryAbility:startAttack()
              -- sb.logInfo("[%s] %s fist continued the combo", os.clock(), activeItem.hand())
              advanceFistCombo()
            end
          end
        elseif activeItem.callOtherHandScript("triggerComboAttack", self.comboStep) then
          -- sb.logInfo("[%s] %s fist triggered opposing attack", os.clock(), activeItem.hand())
          advanceFistCombo()
        end
      end
    else
      if self.primaryAbility:canStartAttack() then
        self.primaryAbility:startAttack()
        if activeItem.callOtherHandScript("resetFistCombo") then
          -- sb.logInfo("[%s] %s fist started a combo", os.clock(), activeItem.hand())
          advanceFistCombo()
        end
      end
    end
  end

  if self.shieldTransformTimer > 0 and self.shieldTransformTimer < dt then
    --setOrbPosition(1)
  end
  
  if self.shieldTransformTimer > 0 then
    self.shieldTransformTimer = math.max(0, self.shieldTransformTimer - dt)
    if self.shieldTransformTimer == 0 then
      self.shieldTimer = self.shieldTime
    end
    --setOrbAnimationState("unshield")
  end

  self.shieldTimer = math.max(0, self.shieldTimer - dt)

  if self.primaryAbility.shieldActive then
    self.primaryAbility.damageListener:update()
  end

  if self.shieldTransformTimer > 0 then
    local transformRatio =  self.shieldTransformTimer / self.shieldTransformTime
    setOrbPosition(0.3 + 0.7 * transformRatio, 0.75 - 0.75 * transformRatio)
    animator.resetTransformationGroup("orbs")
    animator.translateTransformationGroup("orbs", {transformRatio * -1.5 + 0.5, 0})
  elseif self.shieldTimer > 0 then
    --local transformRatio =  0.5 - self.shieldTimer / self.shieldTime
    --animator.translateTransformationGroup("orbs", {2 * -transformRatio, 0})
    if self.shieldTimer <= 0.1 then
      local transformRatio =  self.shieldTimer / 0.1
      setOrbPosition(1 - 0.7 * transformRatio, 0.75 * transformRatio)
      animator.resetTransformationGroup("orbs")
      animator.translateTransformationGroup("orbs", {transformRatio * 1.5 - 1, 0})
      for i = 1, 3 do
        animator.setAnimationState("orb"..i, storage.projectileIds[i] == false and "unshield" or "hidden")
      end
    end
  else
    if self.primaryAbility.shieldActive then
      self.primaryAbility:deactivateShield()
      setOrbPosition(1)
    end
    animator.resetTransformationGroup("orbs")
    animator.rotateTransformationGroup("orbs", -self.weapon.aimAngle or 0)
    animator.translateTransformationGroup("orbs", {-0.25, 0})
    for i = 1, 3 do
      animator.rotateTransformationGroup("orb"..i, self.orbitRate * dt)
      animator.setAnimationState("orb"..i, storage.projectileIds[i] == false and (self.weapon:isFrontHand() and "orbF" or "orbB") or "hidden")
    end
  end


  self.weapon:update(dt, fireMode, shiftHeld)
  --updateAim()
  updateHand()
end

function uninit()
  if unloaded then
    activeItem.callOtherHandScript("resetFistCombo")
  end
  activeItem.setItemShieldPolys()
  activeItem.setItemDamageSources()
  status.clearPersistentEffects("magnorbShield")
  animator.stopAllSounds("shieldLoop")
  self.weapon:uninit()
end

function Punch:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()
  fireOrb()

  animator.setAnimationState("attack", "fire")
  animator.playSound("fire")

  status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.05)

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
    
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  self.cooldownTimer = self:cooldownTime()
end

-- update which image we're using and keep the weapon visually in front of the hand
function updateHand()
  local isFrontHand = self.weapon:isFrontHand()
  animator.setGlobalTag("hand", isFrontHand and "front" or "back")
  animator.resetTransformationGroup("swoosh")
  animator.scaleTransformationGroup("swoosh", isFrontHand and {1, 1} or {1, -1})
  activeItem.setOutsideOfHand(isFrontHand)
end

function fireOrb()
  local nextOrbIndex = nextOrb()
  if nextOrbIndex then
    fire(nextOrbIndex)
  end
end

function nextOrb()
  for i = 1, 3 do
    if not storage.projectileIds[i] then
      return i
    end
  end
end

function availableOrbCount()
  local available = 0
  for i = 1, 3 do
    if not storage.projectileIds[i] then
      available = available + 1
    end
  end
  return available
end

-- called remotely to attempt to perform a combo-continuing attack
function triggerComboAttack(comboStep)
  if self.primaryAbility:canStartAttack() then
    -- sb.logInfo("%s fist received combo trigger for combostep %s", activeItem.hand(), comboStep)
    if comboStep == self.comboSteps then
      startFinisher()
      self.comboFinisher:startAttack()
    else
      self.primaryAbility:startAttack()
    end
    return true
  else
    return false
  end
end

function startFinisher()
  if not self.shieldActive then
    self.primaryAbility:activateShield()
  end
  setOrbAnimationState("shield")
  self.shieldTransformTimer = self.shieldTransformTime
end

function fire(orbIndex)
  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.ownerAimPosition = activeItem.ownerAimPosition()
  local firePos = firePosition(orbIndex)
  if world.lineCollision(mcontroller.position(), firePos) then return end
  local projectileId = world.spawnProjectile(
      self.projectileType,
      firePosition(orbIndex),
      activeItem.ownerEntityId(),
      aimVector(orbIndex),
      false,
      params
    )
  if projectileId then
    storage.projectileIds[orbIndex] = projectileId
    self.cooldownTimer = self.cooldownTime
    animator.playSound("launch")
  end
end

function firePosition(orbIndex)
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("orb"..orbIndex, "orbPosition")))
end

function aimVector(orbIndex)
  return vec2.norm(world.distance(activeItem.ownerAimPosition(), firePosition(orbIndex)))
end

function checkProjectiles()
  for i, projectileId in ipairs(storage.projectileIds) do
    if projectileId and not world.entityExists(projectileId) then
      storage.projectileIds[i] = false
      if self.primaryAbility.shieldActive then
        animator.setAnimationState("orb"..i, "shield")
      end
    end
  end
end

function Punch:activateShield()
  self.shieldActive = true
  animator.resetTransformationGroup("orbs")
  animator.playSound("shieldOn")
  animator.playSound("shieldLoop", -1)
  --self.weapon:setStance(self.stances.shield)
  activeItem.setItemShieldPolys({self.shieldPoly})
  activeItem.setItemDamageSources({self.knockbackDamageSource})
  status.setPersistentEffects("magnorbShield", {{stat = "shieldHealth", amount = self.shieldHealth}})
  self.damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("shieldStamina") then
          animator.playSound("shieldBlock")
        else
          animator.playSound("shieldBreak")
        end
        return
      end
    end
  end)
end

function Punch:deactivateShield()
  self.shieldActive = false
  animator.playSound("shieldOff")
  animator.stopAllSounds("shieldLoop")
  --self.weapon:setStance(self.stances.idle)
  activeItem.setItemShieldPolys()
  activeItem.setItemDamageSources()
  status.clearPersistentEffects("magnorbShield")
end

function setOrbPosition(spaceFactor, distance)
  for i = 1, 3 do
    animator.resetTransformationGroup("orb"..i)
    animator.translateTransformationGroup("orb"..i, {distance or 0, 0})
    animator.rotateTransformationGroup("orb"..i, 2 * math.pi * spaceFactor * ((i - 2) / 3))
  end
end

function setOrbAnimationState(newState)
  for i = 1, 3 do
    if not storage.projectileIds[i] then
      animator.setAnimationState("orb"..i, newState)
    end
  end
end

-- advance to the next step of the combo
function advanceFistCombo()
  self.comboTimer = 0
  if self.comboStep < self.comboSteps then
    -- sb.logInfo("%s fist advancing combo from step %s to %s", activeItem.hand(), self.comboStep, self.comboStep + 1)
    self.comboStep = self.comboStep + 1
  end
end

-- interrupt the combo for various reasons
function resetFistCombo()
  -- sb.logInfo("%s fist resetting combo from step %s to 0", activeItem.hand(), self.comboStep)
  self.comboStep = 0
  self.comboTimer = nil
  return true
end

-- complete the combo, reset and trigger cooldown
function finishFistCombo()
  resetFistCombo()
  self.primaryAbility.cooldownTimer = self.comboCooldown
end

function Weapon:updateAim()
  for _,group in pairs(self.transformationGroups) do
    animator.resetTransformationGroup(group.name)
    animator.translateTransformationGroup(group.name, group.offset)
    animator.rotateTransformationGroup(group.name, group.rotation, group.rotationCenter)
    animator.translateTransformationGroup(group.name, self.weaponOffset)
    animator.rotateTransformationGroup(group.name, self.relativeWeaponRotation, self.relativeWeaponRotationCenter)
  end

  animator.resetTransformationGroup("forscale")
  animator.scaleTransformationGroup("forscale", {0.25, 0.25})

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
