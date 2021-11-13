require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.energyMultiplier = 0
  animator.setAnimationState("reload", "off")

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.shiftHeld = shiftHeld

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if (self.fireMode == (self.activatingFireMode or self.abilitySlot) or self.fireMode == "alt")
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    elseif self.fireMode == "alt" and status.overConsumeResource("energy", self:energyPerShot()) then
      
    end
  end

  self.accurateFire = mcontroller.crouching()
end

function GunFire:auto()
  
  self.weapon:setStance(self.stances.prefire)
  while self.shiftHeld and self.fireMode == "primary" do
    local targets = enemyQuery(mcontroller.position(), 25, {}, activeItem.ownerEntityId(), false)
    local distance = nil
    local entityId = nil
    if targets then
      for _,id in ipairs(targets) do
        local newDistance = world.distance(world.entityPosition(id), mcontroller.position())
        if not distance or (vec2.mag(newDistance) < vec2.mag(distance) and vec2.mag(newDistance) > 3) then
          distance = newDistance
          entityId = id
        end
      end
    end
    if entityId and ((mcontroller.facingDirection() == 1 and distance[1] > 3) or (mcontroller.facingDirection() == -1 and distance[1] < -3)) then
      distance[1] = distance[1] * mcontroller.facingDirection()
      self.weapon.aimAngle = vec2.angle(distance)
    end
    coroutine.yield()
  end

  self.weapon:setStance(self.stances.fire)
  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:cooldown()

  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  animator.setAnimationState("reload", "on")
  animator.playSound("reload")
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

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireBeam(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)

end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = params.power or self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
      projectileType,
      firePosition or self:firePosition(),
      activeItem.ownerEntityId(),
      self:aimVector(self.accurateFire and 0 or (innacuracy or self.inaccuracy)),
      false,
      params
      )
  end
  return projectileId
end

function GunFire:firePosition(xOffset)
  local offset = copy(self.weapon.muzzleOffset)
  offset[2] = 0.5
  offset[1] = offset[1] - 0.5 - (xOffset or 0)
  return vec2.add(mcontroller.position(), activeItem.handPosition(offset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:uninit()

end
