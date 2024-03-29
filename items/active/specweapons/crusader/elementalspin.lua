require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

ElementalSpin = WeaponAbility:new()

function ElementalSpin:init()
  self:reset()
  self.cooldownTimer = self.cooldownTime
end

function ElementalSpin:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.weapon.currentAbility == nil and self.cooldownTimer == 0 and fireMode == "alt" and not status.resourceLocked("energy") then
    self:setState(self.preWindup)
  end
end

function ElementalSpin:preWindup()
  self.weapon:setStance(self.stances.preWindup)
  self.weapon:updateAim()
  animator.playSound("fire10")
  animator.setAnimationState("swoosh", "fire10")
  local duration = self.stances.preWindup.duration
  while self.fireMode == "alt" and duration > 0 do
    duration = math.max(0, duration - self.dt)
    coroutine.yield()
  end
  if duration > 0 then
    animator.stopAllSounds("fire10")
    animator.setAnimationState("swoosh", "idle")
    return
  end
  self:setState(self.windup)
end

function ElementalSpin:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()
  animator.setAnimationState("swoosh", "idle")
  animator.setAnimationState("spinSwoosh", "spin")
  animator.setParticleEmitterActive(self.weapon.elementalType.."Spin", true)
  self.weapon.aimAngle = 0
  activeItem.setOutsideOfHand(true)

  animator.playSound("fire11")
  animator.playSound(self.weapon.elementalType.."Spin", -1)

  local duration = self.stances.windup.duration
  while self.fireMode == "alt" or duration > 0 do
    duration = math.max(0, duration - self.dt)
    self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(self.spinRate * self.dt)

    if status.overConsumeResource("energy", self.energyUsage * self.dt) then
      local damageArea = partDamageArea("spinSwoosh")
      self.weapon:setDamage(self.damageConfig, damageArea)
    elseif duration == 0 then
      break
    end

    coroutine.yield()
  end

  animator.stopAllSounds("electricSpin")
  animator.stopAllSounds("fire11")
  if status.overConsumeResource("energy", self.projectileEnergyCost) then
    self:setState(self.fire)
  end

  self.cooldownTimer = self.cooldownTime
end

function ElementalSpin:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setParticleEmitterActive(self.weapon.elementalType.."Spin", false)
  animator.setAnimationState("spinSwoosh", "idle")
  animator.playSound("electricSpinFire")

  local position = vec2.add(mcontroller.position(), activeItem.handPosition())
  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.power = params.power * config.getParameter("damageLevelMultiplier")
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {self.weapon.aimDirection, 0}, false, params)

  util.wait(self.stances.fire.duration)
end

function ElementalSpin:reset()
  animator.setAnimationState("spinSwoosh", "idle")
  animator.setParticleEmitterActive(self.weapon.elementalType.."Spin", false)
  activeItem.setOutsideOfHand(false)
  animator.stopAllSounds("electricSpin")
end

function ElementalSpin:uninit()
  self:reset()
end
