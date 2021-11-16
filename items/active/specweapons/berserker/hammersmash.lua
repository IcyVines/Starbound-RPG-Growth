require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/melee/meleeslash.lua"

-- Hammer primary attack
-- Extends default melee attack and overrides windup and fire

HammerSmash = MeleeSlash:new()

function HammerSmash:init()
  self.stances.windup.duration = self.fireTime - self.stances.preslash.duration - self.stances.fire.duration
  MeleeSlash.init(self)
  self:setupInterpolation()
  self.cooldownTimer = self.fireTime
  _, self.damageGivenUpdate = status.inflictedDamageSince()
  self.killCount = 0
  self.killTimer = 0
end

function HammerSmash:update(dt, fireMode, shiftHeld)
  MeleeSlash.update(self, dt, fireMode, shiftHeld)

  self:updateDamageGiven(dt)

  animator.setGlobalTag("bloodMod", self.killCount)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if (self.fireMode == "primary")
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    end
  end

  if (self.fireMode == "alt")
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0 then
      self:setState(self.windup)
  end

end

function HammerSmash:updateDamageGiven(dt)
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 and notification.damageDealt > notification.healthLost and notification.damageSourceKind == "ivrpg_berserkershammer" then
        self.killTimer = 5
        self.killCount = math.min(self.killCount + 1, 6)
      end
    end
  end

  if self.killTimer > 0 then
    self.killTimer = math.max(0, self.killTimer - dt)
  else
    self.killCount = math.max(0, self.killCount - 1)
    if self.killCount ~= 0 then
      self.killTimer = 5
    end
  end

end

-- Fire Start

function HammerSmash:auto()
  self.weapon:setStance(self.stances.fireGun)
  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function HammerSmash:cooldown(alt)

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

function HammerSmash:muzzleFlash()
  animator.resetTransformationGroup("muzzle")
  animator.translateTransformationGroup("muzzle", self.weapon.muzzleOffset)
  --animator.rotateTransformationGroup("muzzle", self.weapon.aimAngle)
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fireGun")

  animator.setLightActive("muzzleFlash", true)
end

function HammerSmash:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = (params.power or self:damagePerShot()) + self.killCount
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) + self.killCount do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
      projectileType,
      firePosition or self:firePosition(),
      activeItem.ownerEntityId(),
      self:aimVector(innacuracy or self.inaccuracy / (1 + self.killCount)),
      false,
      params
      )
  end
  return projectileId
end

-- Fire End


function HammerSmash:windup(windupProgress)
  self.weapon.aimAngle = 0
  self.weapon:setStance(self.stances.windup)

  local windupProgress = windupProgress or 0
  local bounceProgress = 0
  while self.fireMode == "alt" and (self.allowHold ~= false or windupProgress < 1) do
    if windupProgress < 1 then
      windupProgress = math.min(1, windupProgress + (self.dt / self.stances.windup.duration))
      self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
    else
      bounceProgress = math.min(1, bounceProgress + (self.dt / self.stances.windup.bounceTime))
      self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:bounceWeaponAngle(bounceProgress)
    end
    coroutine.yield()
  end

  if windupProgress >= 0 then
    self:setState(self.fire, windupProgress)
  else
    self:setState(self.winddown, windupProgress)
  end
end

function HammerSmash:winddown(windupProgress)
  self.weapon:setStance(self.stances.windup)

  while windupProgress > 0 do
    if self.fireMode == "alt" then
      self:setState(self.windup, windupProgress)
      return true
    end

    windupProgress = math.max(0, windupProgress - (self.dt / self.stances.windup.duration))
    self.weapon.relativeWeaponRotation, self.weapon.relativeArmRotation = self:windupAngle(windupProgress)
    coroutine.yield()
  end
end

function HammerSmash:fire(windupProgress)
  local windupProgress = windupProgress or 1

  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("swoosh", "fire")
  animator.playSound("fire")
  animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")

  local smashMomentum = self.smashMomentum
  smashMomentum[1] = smashMomentum[1] * mcontroller.facingDirection()
  mcontroller.addMomentum(smashMomentum)

  local smashTimer = self.stances.fire.smashTimer
  local duration = self.stances.fire.duration
  while smashTimer > 0 or duration > 0 do
    smashTimer = math.max(0, smashTimer - self.dt)
    duration = math.max(0, duration - self.dt)

    local damageArea = partDamageArea("swoosh")
    if not damageArea and smashTimer > 0 then
      damageArea = partDamageArea("blade")
    end
    local damageReset = self.damageConfig.baseDamage
    self.damageConfig.baseDamage = self.damageConfig.baseDamage * math.min(1, windupProgress)
    self.weapon:setDamage(self.damageConfig, damageArea, duration)
    self.damageConfig.baseDamage = damageReset

    if smashTimer > 0 then
      local groundImpact = world.polyCollision(poly.translate(poly.handPosition(animator.partPoly("blade", "groundImpactPoly")), mcontroller.position()))
      if mcontroller.onGround() or groundImpact then
        smashTimer = 0
        if groundImpact then
          animator.burstParticleEmitter("groundImpact")
          animator.playSound("groundImpact")
        end
      end
    end
    coroutine.yield()
  end

  self.cooldownTimer = self.fireTime / 3
end

function HammerSmash:setupInterpolation()
  for i, v in ipairs(self.stances.windup.bounceWeaponAngle) do
    v[2] = interp[v[2]]
  end
  for i, v in ipairs(self.stances.windup.bounceArmAngle) do
    v[2] = interp[v[2]]
  end
  for i, v in ipairs(self.stances.windup.weaponAngle) do
    v[2] = interp[v[2]]
  end
  for i, v in ipairs(self.stances.windup.armAngle) do
    v[2] = interp[v[2]]
  end
end

function HammerSmash:bounceWeaponAngle(ratio)
  local weaponAngle = interp.ranges(ratio, self.stances.windup.bounceWeaponAngle)
  local armAngle = interp.ranges(ratio, self.stances.windup.bounceArmAngle)

  return util.toRadians(weaponAngle), util.toRadians(armAngle)
end

function HammerSmash:windupAngle(ratio)
  local weaponRotation = interp.ranges(ratio, self.stances.windup.weaponAngle)
  local armRotation = interp.ranges(ratio, self.stances.windup.armAngle)

  return util.toRadians(weaponRotation), util.toRadians(armRotation)
end

function HammerSmash:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function HammerSmash:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function HammerSmash:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function HammerSmash:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end
