require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/ranged/gunfire.lua"

AltFireAttack = GunFire:new()

function AltFireAttack:new(abilityConfig)
  local primary = config.getParameter("primaryAbility")
  return GunFire.new(self, sb.jsonMerge(primary, abilityConfig))
end

function AltFireAttack:init()
  self.cooldownTimer = self.fireTime
  self.knockbackFactor = config.getParameter("altAbility.knockbackFactor", 10)
  sb.logInfo(self.knockbackFactor)
end

function AltFireAttack:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    
    if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    elseif self.fireType == "burst" then
      self:setState(self.burst)
    end
    mcontroller.setVelocity(vec2.add(mcontroller.velocity(), vec2.mul(vec2.rotate(self:aimVector(0), math.pi), self.knockbackFactor)))
  end
end

function AltFireAttack:muzzleFlash()
  if not self.hidePrimaryMuzzleFlash then
    animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
    animator.setAnimationState("firing", "fire")
    animator.setLightActive("muzzleFlash", true)
  end
  
  if self.useParticleEmitter == nil or self.useParticleEmitter then
    animator.burstParticleEmitter("altMuzzleFlash", true)
  end

  if self.usePrimaryFireSound then
    animator.playSound("fire")
  else
    animator.playSound("altFire")
  end
end

function AltFireAttack:firePosition()
  if self.firePositionPart then
    return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint(self.firePositionPart, "firePosition")))
  else
    return GunFire.firePosition(self)
  end
end
