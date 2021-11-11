require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.ACI = config.getParameter("rpg_ACI")
  self.charges = {}
  self.chargeToColor = root.assetJson("/professions/alchemist/potionHues.config")
  self.potionConfig = root.assetJson("/professions/alchemist/ivrpg_potion.config")

  local count = 1
  local tooltipFields = {}
  for i=2,4 do
    local ACI = self.ACI["itemSlot" .. tostring(i)]
    local animation = "charge" .. tostring(count)
    local potion = self.potionConfig[ACI and ACI.name or nil]
    if ACI then
      self.charges[count] = ACI.name
      if self.charges[count] then
        animator.setAnimationState(animation, "on")
        animator.setGlobalTag(animation .. "Mod", "?multiply=" .. (potion and potion.hue or "000000") .. "FF")
      else
        animator.setAnimationState(animation, "off")
      end
    end
    tooltipFields[animation .. "Label"] = potion and potion.name or "Empty"
    count = count + 1
  end
   
  activeItem.setInstanceValue("tooltipFields", tooltipFields)
  self.currentCharge = config.getParameter("currentCharge", 3)
  if not self.charges[self.currentCharge] then
    self:increment(1)
  end
  self.potion = self.charges[self.currentCharge] and self.potionConfig[self.charges[self.currentCharge]] or nil

  if self.potion then
    animator.setAnimationState("charge0", "on")
    animator.setGlobalTag("charge0Mod", "?multiply=" .. self.potion.hue)
  else
    animator.setAnimationState("charge0", "off")
  end

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  self.potion = self.potionConfig[self.charges[self.currentCharge]]

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.shiftHeld and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.fireMode ~= self.lastActiveFireMode
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and self.currentCharge then
      self:increment(1)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot) and not self.shiftHeld
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    elseif self.fireType == "burst" then
      self:setState(self.burst)
    end
  end

  self.lastActiveFireMode = self.fireMode
end

function GunFire:increment(count)
  if count >= 4 then
    return
  end
  self.currentCharge = (self.currentCharge % 3) + 1
  self.cooldownTimer = 0.1
  activeItem.setInstanceValue("currentCharge", self.currentCharge)
  if self.charges[self.currentCharge] then
    animator.playSound("fill")
    animator.setAnimationState("charge0", "on")
    animator.setGlobalTag("charge0Mod", "?multiply=" .. self.chargeToColor[self.charges[self.currentCharge]] .. "FF")
  else
    self:increment(count + 1)
  end
end

function GunFire:auto()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:burst()
  self.weapon:setStance(self.stances.fire)

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:fireProjectile()
    self:muzzleFlash()
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    util.wait(self.burstTime)
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function GunFire:cooldown()
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

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
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
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
end

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
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
