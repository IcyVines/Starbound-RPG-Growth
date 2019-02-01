require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Mark = WeaponAbility:new()

function Mark:init()
  self:reset()
  self.holdDamageConfig = config.getParameter("altAbility.holdDamageConfig", {})
  self.holdDamageMultiplier = config.getParameter("altAbility.holdDamageMultiplier", 0.1)
  self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
  self.chargeTimer = 0
  self.cooldownTimer = 0.5
  self.id = activeItem.ownerEntityId()
  activeItem.setCursor("/cursors/pointer.cursor")
end

function Mark:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.powerMultiplier = activeItem.ownerPowerMultiplier()

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and not status.resourceLocked("energy") then
    self:setState(self.charge)
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - dt, 0)
  end
end

function Mark:charge()
  self.weapon:setStance(self.stances.charge)
  self.weapon:updateAim()

  animator.setAnimationState("chargeAnimation", "charge")
  activeItem.setCursor("/cursors/charge2.cursor")

  local chargeTimer = 0
  local charged = false
  local damageArea = partDamageArea("blade")
  while self.fireMode == "alt" and status.overConsumeResource("energy", (charged and 0 or (self.maxEnergyUsage / self.chargeTime)) * self.dt) do
    chargeTimer = math.min(self.chargeTime, chargeTimer + self.dt)
    charged = chargeTimer == self.chargeTime
    if charged then activeItem.setCursor("/cursors/chargeready.cursor") end
    status.setResourcePercentage("energyRegenBlock", 1.0)
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
    coroutine.yield()
  end

  if chargeTimer > self.minChargeTime then
    self:setState(self.throw, chargeTimer / self.chargeTime)
  end
end

function Mark:throw(charge)
  self.weapon:setStance(self.stances.throw)
  self.weapon:updateAim()

  --[[animator.burstParticleEmitter(self.weapon.elementalType .. "swoosh")
  animator.setAnimationState("swoosh", "fire")]]
  animator.setAnimationState("throwAnimation", "thrown")
  animator.setAnimationState("chargeAnimation", "idle")
  activeItem.setCursor("/cursors/pointer.cursor")
  animator.playSound("fire")

  self.initialPosition = vec2.add(mcontroller.position(), activeItem.handPosition())
  self.endPosition = activeItem.ownerAimPosition()
  local aimDirection = {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle), math.sin(self.weapon.aimAngle)}
  local distance = world.distance(self.endPosition, self.initialPosition)
  local magnitude = vec2.mag(distance)

  world.spawnProjectile("ivrpgwgungnirthrown", self:firePosition(), self.id, self:aimVector(), false, {
    power = self.damageConfig.projectileDamage * self.powerMultiplier * charge,
    tracking = charge^3,
    bounces = math.floor(3*charge)
  })

  -- freeze in mid air for a short amount of time
  util.wait(self.freezeTime, function(dt)
    mcontroller.controlModifiers({
      movementSuppressed = true,
      gravityEnabled = false
    })
    mcontroller.setYVelocity(0)
  end)

  self.weapon.aimAngle = 0
  self.weapon:setStance(self.stances.idle)
  animator.setAnimationState("throwAnimation", "return")
  util.wait(self.stances.idle.duration, function(dt)

  end)

  self.cooldownTimer = 0.5
end

function Mark:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.stances.throw.weaponOffset))
end

function Mark:aimVector()
  --local aimVector = {mcontroller.facingDirection(), 0}
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle - 7.5*math.pi*2/180)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function Mark:reset()
  animator.setAnimationState("chargeAnimation", "idle")
  animator.setAnimationState("throwAnimation", "idle")
  activeItem.setCursor("/cursors/pointer.cursor")
end

function Mark:uninit()
  self:reset()
end