require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.id = activeItem.ownerEntityId()
  self.cooldownTimer = self.fireTime
  self.altCooldownTimer = self.fireTime
  self.active = false
  self.altactive = false
  self.emoting = true
  self.target = nil
  self.blinkTimer = 1
  self.attackTimer = 0.5
  self.health = status.resource("health")
  self.damageArea = config.getParameter("primaryAbility.damageArea", {})
  self.energyCost = config.getParameter("primaryAbility.energyUsage", {})
  animator.setSoundVolume("speak", 0.4)
  animator.setSoundPitch("speak", 1.2)
  self.weapon.onLeaveAbility = function()
    --self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.altCooldownTimer = math.max(0, self.altCooldownTimer - self.dt)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not self.active
    and not status.resourceLocked("energy") then
    self:setState(self.raise)
  elseif self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and self.altCooldownTimer == 0
    and not self.altactive
    and not status.resourceLocked("energy") then
    self:setState(self.holdout)
  end

  if self.active then
    if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) or status.resourceLocked("energy") then
      self.cooldownTimer = self.fireTime
      self:setState(self.cooldown)
      return
    end
    self:searchForTarget(15, 10)
    self:changeAnimation()
    self:attackTarget()
    self.attackTimer = math.max(0, self.attackTimer - dt)
  end

  if self.altactive and self.altCooldownTimer == 0 then
    if self.fireMode ~= "alt" or status.resourceLocked("energy") then
      self.cooldownTimer = self.fireTime
      self:setState(self.cooldown)
      return
    end
    self:searchForTarget(5, 2)
    self:setState(self.bite)
  end

  self.health = status.resource("health")
end

function GunFire:raise()
  animator.setAnimationState("firing", "fire")
  animator.setSoundVolume("open", 0.25)
  animator.playSound("open")
  local progress = 0
  util.wait(self.stances.fire.duration, function()
    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.fire.armRotation))
    progress = math.min(1.0, progress + (self.dt / self.stances.fire.duration))
  end)
  self.weapon:setStance(self.stances.fire)
  self.active = true
  self.blinkTimer = 1
  self.attackTimer = 0.5
  animator.playSound("speak")
end

function GunFire:holdout()
  animator.setAnimationState("firing", "fire")
  animator.setSoundVolume("open", 0.25)
  animator.playSound("open")
  local progress = 0
  util.wait(self.stances.altfire.duration, function()
    local from = self.stances.idle.weaponOffset or {0,0}
    local to = self.stances.altfire.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.altfire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.altfire.armRotation))
    progress = math.min(1.0, progress + (self.dt / self.stances.altfire.duration))
  end)
  self.weapon:setStance(self.stances.altfire)
  self.altactive = true
  animator.playSound("speak")
end

function GunFire:cooldown(closed)
  self.active = false
  self.altactive = false
  animator.setAnimationState("firing", closed and "off" or "close")
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()
  
  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))
    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

function GunFire:changeAnimation()
  self.emoting = animator.animationState("firing") == "blink" or animator.animationState("firing") == "cry" or animator.animationState("firing") == "jiggle"
  if self.emoting then return end
  if self.target then
    animator.setAnimationState("firing", "angry")
  else
    animator.setAnimationState("firing", "idle")
    if status.resource("health") < self.health then
      animator.setAnimationState("firing", "cry")
    elseif self.blinkTimer <= 0 and (math.random(240) < 2 or self.blinkTimer < -12) then
      animator.setAnimationState("firing", "blink")
      self.blinkTimer = 1.5
    end
  end
  self.blinkTimer = self.blinkTimer - self.dt
end

function GunFire:searchForTarget(xRange, yRange)
  local position = mcontroller.position()
  local direction = mcontroller.facingDirection()
  local crouch = mcontroller.crouching() and 1 or 0
  local bottomLeft = vec2.add({position[1] + (direction - 1) * xRange / 2, position[2] + 0.5 - yRange - crouch},  activeItem.handPosition({-1,0.35}))
  local topRight = vec2.add({position[1] + (direction + 1) * xRange / 2, position[2] + 0.5 + yRange - crouch}, activeItem.handPosition({-1,0.35})) 
  local targetIds = world.entityQuery(bottomLeft, topRight, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })
  shuffle(targetIds)
  self.target = nil
  for i,id in ipairs(targetIds) do
    if (world.entityDamageTeam(id).type == "enemy" or (world.entityDamageTeam(id).type == "pvp" and world.entityCanDamage(self.id, id)))
      and not world.lineCollision(world.entityPosition(id), position, {"Block", "Slippery", "Dynamic"}) then
      self.target = id
    end
  end
end

function GunFire:attackTarget()
  if self.attackTimer == 0 and self.target and world.entityExists(self.target) then
    local speed = 50
    local crouch = mcontroller.crouching() and 1 or 0
    local myPos = {mcontroller.xPosition() + 2.2 * mcontroller.facingDirection(), mcontroller.yPosition() + 0.5 - crouch}
    local directionTo = vec2.mul(vec2.norm(world.distance(world.entityPosition(self.target), myPos)), speed)
    local velocity = world.entityVelocity(self.target)
    directionTo[1] = directionTo[1] + velocity[1]
    directionTo[2] = directionTo[2] + velocity[2]/2
    animator.setSoundVolume("fire", 0.5)
    animator.playSound("fire")
    status.overConsumeResource("energy", self.energyCost / 10)
    world.spawnProjectile(
      "ivrpgcoinprojectile" .. tostring(math.random(7)),
      myPos,
      self.id,
      directionTo,
      false,
      {speed = speed, power = 10 * activeItem.ownerPowerMultiplier()}
    )
    self.attackTimer = 0.2
  end
end

function GunFire:bite()
  if self.target and world.entityExists(self.target) then
    self.target = nil
    animator.stopAllSounds("speak")
    status.overConsumeResource("energy", self.energyCost)
    animator.setAnimationState("firing", "bite")
    self.altCooldownTimer = self.fireTime * 3 + 0.4
    self.cooldownTimer = self.fireTime + 0.4
    util.wait(0.1)
    local damageArea = poly.translate(self.damageArea, activeItem.handPosition({-1, mcontroller.crouching() and 1.3 or 0.3}))     
    local progress = 0
    util.wait(0.3, function()
      if progress < 0.2 then self.weapon:setDamage(self.damageConfig, damageArea) end
      progress = progress + self.dt
    end)
    self:setState(self.cooldown, true)
  end
end

function GunFire:uninit()
end

function Weapon:updateAim()
  for _,group in pairs(self.transformationGroups) do
    animator.resetTransformationGroup(group.name)
    animator.translateTransformationGroup(group.name, group.offset)
    animator.rotateTransformationGroup(group.name, group.rotation, group.rotationCenter)
    animator.translateTransformationGroup(group.name, self.weaponOffset)
    animator.rotateTransformationGroup(group.name, self.relativeWeaponRotation, self.relativeWeaponRotationCenter)
    animator.scaleTransformationGroup(group.name, {0.8, 0.8})
  end

  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.aimOffset, activeItem.ownerAimPosition())
  if self.stance.allowRotate then
    self.aimAngle = aimAngle < 0 and 0 or math.min(math.pi/6,aimAngle)
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