require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"

Parry = WeaponAbility:new()

function Parry:init()

  self.name = item.name()
  self.bonus = self.name == "knightaegissword" and 1 or (self.name == "knightaegissword2" and 1.5 or 2)
  self.perfectBlockTime = self.bonus*.1

  self.cooldownTimer = 0
  self.holdTimer = 0
  self.holdTime = config.getParameter("minHoldTime", 0.6)
  self.active = false
  self.knockback = config.getParameter("knockback", 0)
  self.perfectBlockDirectives = config.getParameter("perfectBlockDirectives", "")
  
  --self.perfectBlockTime = config.getParameter("perfectBlockTime", 0.2)

  --self.bonus = self.name == "knightaegissword" and 1 or (self.name == "knightaegissword2" and 1.5 or 2)
  --self.perfectBlockTime = self.bonus*.1

end

function Parry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.holdTimer = math.max(0, self.holdTimer - dt)

  if (fireMode ~= "alt" and self.holdTimer == 0) or not status.resourcePositive("shieldStamina") then
      self.active = false
  else
      self.active = true
  end

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
    and self.cooldownTimer == 0
    and status.resourcePositive("shieldStamina") then

    self:setState(self.parry)
    if status.resourcePositive("perfectBlock") then
      animator.setGlobalTag("directives", self.perfectBlockDirectives)
    else
      animator.setGlobalTag("directives", "")
    end
  end

  

end

function Parry:parry()
  self.holdTimer = self.holdTime
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()

  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth*self.bonus}})

  local blockPoly = animator.partPoly("parryShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  --if self.knockback > 0 then
  self.knockback = status.resourcePositive("perfectBlock") and 40 or 20
  local knockbackDamageSource = {
    poly = blockPoly,
    damage = 0,
    damageType = "Knockback",
    sourceEntity = activeItem.ownerEntityId(),
    team = activeItem.ownerTeam(),
    knockback = self.knockback,
    rayCheck = true,
    damageRepeatTimeout = 0.25
  }
  activeItem.setItemDamageSources({ knockbackDamageSource })
  --end

  animator.setAnimationState("parryShield", "active")
  if self.bonus == 2 then animator.setAnimationState("auraLoop", "idle") end
  animator.playSound("guard")

  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
        if status.resourcePositive("perfectBlock") then
          animator.playSound("perfectBlock")
          --animator.burstParticleEmitter("perfectBlock")
          self:refreshPerfectBlock()
        elseif status.resourcePositive("shieldStamina") then
          animator.playSound("parry")
        end
        animator.setAnimationState("parryShield", "block")
        return
      end
    end
  end)

  self:refreshPerfectBlock()

  util.wait(self.parryTime*self.bonus, function(dt)
    --Interrupt when running out of shield stamina
    if not self.active then
      if not status.resourcePositive("shieldStamina") then
        animator.playSound("break")
      end
      return true
    end

    damageListener:update()
  end)

  self.cooldownTimer = self.cooldownTime
  activeItem.setItemShieldPolys({})
end

function Parry:reset()
  animator.setGlobalTag("directives", "")
  animator.setAnimationState("parryShield", "inactive")
  if self.bonus == 2 then animator.setAnimationState("auraLoop", "aura") end
  status.clearPersistentEffects("broadswordParry")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
end

function Parry:uninit()
  self:reset()
end

function Parry:refreshPerfectBlock()
  local perfectBlockTimeAdded = math.max(0, math.min(status.resource("perfectBlockLimit"), self.perfectBlockTime - status.resource("perfectBlock")))
  status.overConsumeResource("perfectBlockLimit", perfectBlockTimeAdded)
  status.modifyResource("perfectBlock", perfectBlockTimeAdded)
end