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
  self.active = false
  self.timer = 0

  while self.fireMode == "primary" do
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
    self.timer = self.timer + self.dt
    if self.timer > 0.05 then
      self.timer = self.timer - 0.05
      if not status.resourceLocked("energy")
        and not world.lineTileCollision(mcontroller.position(), self:firePosition())
        and status.overConsumeResource("energy", 100*self.dt) then
        if not self.active then animator.playSound("flame", -1) end
        self.active = true
        world.spawnProjectile("flamethrower", self:firePosition(), activeItem.ownerEntityId(), self:aimVector(0.075), false, {power = 7.5, speed = 25})
      else
        animator.stopAllSounds("flame")
        if self.active then
          animator.playSound("flameOff")
          self.active = false
        end
      end
    end
    coroutine.yield()
  end

  if self.active then
    animator.stopAllSounds("flame")
    animator.playSound("flameOff")
  end
  self.cooldownTimer = self:cooldownTime()
end

function SpearStab:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition({5, 3.4}))
end

function SpearStab:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end