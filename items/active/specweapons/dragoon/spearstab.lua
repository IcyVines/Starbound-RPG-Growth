require "/items/active/weapons/melee/meleeslash.lua"

-- Spear stab attack
-- Extends normal melee attack and adds a hold state
SpearStab = MeleeSlash:new()

function SpearStab:init()
  MeleeSlash.init(self)

  self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
end

function SpearStab:fire()
  MeleeSlash.fire(self)

  if self.fireMode == "primary" and self.allowHold ~= false then
    self:setState(self.hold)
  end
end

function SpearStab:hold()
  self.weapon:setStance(self.stances.hold)
  self.weapon:updateAim()

  self.timer = 0
  animator.playSound("meteorCharge")
  self.chargeSound = false

  while self.fireMode == "primary" and status.overConsumeResource("energy", 5*self.dt) do
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
    self.timer = self.timer + self.dt
    if self.timer > 1 and not self.chargeSound then
      self.chargeSound = true
      animator.playSound("meteorChargeHold", -1)
    end
    coroutine.yield()
  end

  animator.stopAllSounds("meteorChargeHold")
  animator.stopAllSounds("meteorCharge")
  if self.timer > 1 then
    local positionModifier = {mcontroller.facingDirection() * 6 * math.cos(self.weapon.aimAngle), 6 * math.sin(self.weapon.aimAngle)}
    local position = vec2.add(vec2.add(mcontroller.position(), activeItem.handPosition()), positionModifier)
    local power = math.min(self.timer*25, 100)
    animator.playSound("meteorFire")
    world.spawnProjectile("ivrpgdragoonsmallmeteor", position, activeItem.ownerEntityId(), positionModifier , false, {power = power, speed = 100, powerMultiplier = activeItem.ownerPowerMultiplier()})
  end
  self.cooldownTimer = self:cooldownTime()
end
