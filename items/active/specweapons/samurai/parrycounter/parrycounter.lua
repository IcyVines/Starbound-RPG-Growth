require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"

Parry = WeaponAbility:new()

function Parry:init()
  Parry:reset()

  self.cooldownTimer = self.cooldownTime
end

function Parry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
    and self.cooldownTimer == 0
    and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.parry)
  end
end

function Parry:parry()
    local stance = self.stances["parry"]
	self.weapon:updateAim()
	self.weapon:setStance(stance)

  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth * (1 + status.statusProperty("ivrpgstrength") * 0.02)}})

  local blockPoly = animator.partPoly("parryShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  animator.setAnimationState("parryShield", "active")
  animator.playSound("guard")

  if stance.flipx and stance.flipy then
		 animator.setPartTag("blade", "directives", "?flipxy")
		 animator.setPartTag("handle", "directives", "?flipxy")
	 elseif stance.flipx and not stance.flipy then
		 animator.setPartTag("blade", "directives", "?flipx")
		 animator.setPartTag("handle", "directives", "?flipx")
	 elseif stance.flipy and not stance.flipx then
		 animator.setPartTag("blade", "directives", "?flipy")
		 animator.setPartTag("handle", "directives", "?flipy")
	 else
		 animator.setPartTag("blade", "directives", "")
		 animator.setPartTag("handle","directives", "")
   end 
  
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
        animator.playSound("parry")
        animator.setAnimationState("parryShield", "block")
		self:setState(self.parrywindup)
        return
      end
    end
  end)

  util.wait(self.parryTime, function(dt)
    --Interrupt when running out of shield stamina
    if not status.resourcePositive("shieldStamina") then return true end

    damageListener:update()
  end)

  self.cooldownTimer = self.cooldownTime
  activeItem.setItemShieldPolys({})
end

function Parry:parrywindup()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
    activeItem.setItemShieldPolys({})
	local stance = self.stances["parryWindup"]
	self.weapon:updateAim()
	self.weapon:setStance(stance)

  if stance.flipx and stance.flipy then
		 animator.setPartTag("blade", "directives", "?flipxy")
		 animator.setPartTag("handle", "directives", "?flipxy")
	 elseif stance.flipx and not stance.flipy then
		 animator.setPartTag("blade", "directives", "?flipx")
		 animator.setPartTag("handle", "directives", "?flipx")
	 elseif stance.flipy and not stance.flipx then
		 animator.setPartTag("blade", "directives", "?flipy")
		 animator.setPartTag("handle", "directives", "?flipy")
	 else
		 animator.setPartTag("blade", "directives", "")
		 animator.setPartTag("handle","directives", "")
   end 
  
  util.wait(self.stances.parryWindup.duration)
    self:setState(self.counter)
end

function Parry:counter()
    local stance = self.stances["counter"]
	self.weapon:updateAim()
	self.weapon:setStance(stance)
	animator.setParticleEmitterActive(self.weapon.elementalType.."Counter", true)
  
  if stance.flipx and stance.flipy then
		 animator.setPartTag("blade", "directives", "?flipxy")
		 animator.setPartTag("handle", "directives", "?flipxy")
	 elseif stance.flipx and not stance.flipy then
		 animator.setPartTag("blade", "directives", "?flipx")
		 animator.setPartTag("handle", "directives", "?flipx")
	 elseif stance.flipy and not stance.flipx then
		 animator.setPartTag("blade", "directives", "?flipy")
		 animator.setPartTag("handle", "directives", "?flipy")
	 else
		 animator.setPartTag("blade", "directives", "")
		 animator.setPartTag("handle","directives", "")
   end 
  
  animator.setAnimationState("swoosh", "fire")
  animator.playSound("fire")

  util.wait(stance.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  self.cooldownTimer = self.cooldownTime
  activeItem.setItemShieldPolys({})
  animator.setParticleEmitterActive(self.weapon.elementalType.."Counter", false)
end

function Parry:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  activeItem.setItemShieldPolys({})
end

function Parry:uninit()
  self:reset()
end
