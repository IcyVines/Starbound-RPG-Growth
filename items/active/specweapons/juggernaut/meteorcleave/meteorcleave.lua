require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

MeteorCleave = WeaponAbility:new()

function MeteorCleave:init()
  self.cooldownTimer = self.cooldownTime
  self.damageGivenUpdate = 5
  self:reset()
end

function MeteorCleave:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == "alt" and self.weapon.currentState == nil and self.cooldownTimer == 0 and not status.resourceLocked("energy")then
    self:setState(self.windup)
  end

  self:updateDamageGiven()
end

function MeteorCleave:updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if "cleavingmeteorfirehammer" == notification.damageSourceKind then
        if notification.healthLost > 0 and notification.damageDealt > notification.healthLost and world.entityExists(notification.targetEntityId) then
          world.spawnProjectile(
            "fireplasmaexplosionstatus",
            world.entityPosition(notification.targetEntityId),
            activeItem.ownerEntityId(),
            {0,0},
            false,
            {timeToLive = 0.25, power = status.stat("powerMultiplier")*50}
          )
        end
      end
    end
  end
end

function MeteorCleave:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  animator.setAnimationState("giantBlade", "charge")
  animator.setParticleEmitterActive(self.weapon.elementalType.."SwordCharge", true)
  animator.playSound(self.weapon.elementalType.."charge")

  local bladeState = "charge"
  local chargeTimer = self.chargeTime
  while self.fireMode == "alt" do
    -- manually update sounds so that we can use elemental variations
    local newState = animator.animationState("giantBlade")
    if newState ~= bladeState then
      if newState == "fullwindup" then
        animator.stopAllSounds(self.weapon.elementalType.."charge")
        animator.playSound(self.weapon.elementalType.."fullwindup")
      elseif newState == "full" then
        animator.playSound(self.weapon.elementalType.."full", -1)
      end
      bladeState = newState
    end

    chargeTimer = math.max(0, chargeTimer - self.dt)
    coroutine.yield()
  end

  if chargeTimer == 0 and status.overConsumeResource("energy", status.resource("energy")) then
    self:setState(self.slash)
  end
end

function MeteorCleave:slash()
  self.weapon:setStance(self.stances.slash)
  self.weapon:updateAim()

  animator.setAnimationState("giantSwoosh", "slash")
  animator.playSound("fire")
  animator.stopAllSounds(self.weapon.elementalType.."full")
  animator.stopAllSounds(self.weapon.elementalType.."charge")

  util.wait(self.stances.slash.duration, function(dt)
    local damageArea = partDamageArea("giantswoosh")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  self.cooldownTimer = self.cooldownTime
end

function MeteorCleave:reset()
  animator.setAnimationState("giantBlade", "idle")
  animator.setParticleEmitterActive(self.weapon.elementalType.."SwordCharge", false)
  animator.stopAllSounds(self.weapon.elementalType.."charge")
  animator.stopAllSounds(self.weapon.elementalType.."full")
end

function MeteorCleave:uninit()
  self:reset()
end
