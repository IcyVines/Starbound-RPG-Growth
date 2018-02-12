require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

PowerPunch = WeaponAbility:new()

function PowerPunch:init()
  self.freezeTimer = 0
  self.cost = config.getParameter("energyCost", 30)
  self.baseDamage = self.damageConfig.baseDamage
  self.initDamage = self.baseDamage
  self.name = item.name()
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function PowerPunch:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.symbiosis = status.statPositive("ivrpgucsymbiosis") and self.name == "roguesiphonclaw3v"

  if self.symbiosis and status.resource("health")/status.stat("maxHealth") <= 0.33 then
    status.setPersistentEffects("ivrpgucsymbiosis", {
      {stat = "powerMultiplier", baseMultiplier = 2}
    })
  elseif self.name == "roguesiphonclaw3v" then
    status.clearPersistentEffects("ivrpgucsymbiosis")
  end

  self.freezeTimer = math.max(0, self.freezeTimer - self.dt)
  if self.freezeTimer > 0 and not mcontroller.onGround() and math.abs(world.gravity(mcontroller.position())) > 0 then
    mcontroller.controlApproachVelocity({0, 0}, 1000)
  end
end

-- used by fist weapon combo system
function PowerPunch:startAttack()
  self:setState(self.windup)

  self.weapon.freezesLeft = 0
  self.freezeTimer = self.freezeTime or 0
end

-- State: windup
function PowerPunch:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)

  self:setState(self.windup2)
end

-- State: windup2
function PowerPunch:windup2()
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)

  self:setState(self.fire)
end

-- State: special
function PowerPunch:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "special")
  animator.playSound("special")

  status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.1)
  local energy = status.resource("energy")
  local energized = status.overConsumeResource("energy", self.cost)

  self.damageConfig.baseDamage = energized and self.baseDamage*3 or self.baseDamage

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("specialswoosh")
    
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  finishFistCombo()
  activeItem.callOtherHandScript("finishFistCombo")
end

function PowerPunch:uninit(unloaded)
  self.weapon:setDamage()
  status.clearPersistentEffects("ivrpgucsymbiosis")
end
