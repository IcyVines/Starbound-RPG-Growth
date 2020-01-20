AdaptableAmmo = WeaponAbility:new()

function AdaptableAmmo:init()
  self.ammoIndex = math.min(config.getParameter("ammoIndex", 1), #self.elementalTypes)
  self:adaptAbility()
  self.lastIndex = config.getParameter("lastIndex", 1)
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function AdaptableAmmo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  self.shiftHeld = shiftHeld
  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) then
    self:setState(self.switch)
  end
end

function AdaptableAmmo:switch()
  if self.shiftHeld then
    local newIndex = self.lastIndex
    self.lastIndex = self.ammoIndex
    self.ammoIndex = newIndex
  else
    self.ammoIndex = (self.ammoIndex % #self.elementalTypes) + 1
    self.lastIndex = 1
  end
  activeItem.setInstanceValue("lastIndex", self.lastIndex)
  activeItem.setInstanceValue("ammoIndex", self.ammoIndex)

  self:adaptAbility()
  animator.playSound("switchElement")

  self.weapon:setStance(self.stances.switch)

  util.wait(self.stances.switch.duration)
end

function AdaptableAmmo:adaptAbility()
  local ability = self.weapon.abilities[self.adaptedAbilityIndex]
  util.mergeTable(ability, self.elementalTypes[self.ammoIndex])
  self.eType = self.ammoIndex == 1 and "nova" or (self.ammoIndex == 2 and "fire" or (self.ammoIndex == 3 and "electric" or "ice"))
  animator.setAnimationState("elementalType", self.ammoIndex)
end

function AdaptableAmmo:uninit()
  
end
