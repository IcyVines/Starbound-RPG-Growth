require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  animator.setGlobalTag("directives", "")
  animator.setGlobalTag("bladeDirectives", "")

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  self.primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(self.primaryAbility)

  self.altAbility = getAltAbility()
  self.weapon:addAbility(self.altAbility)

  self.weapon:init()

  self.inactiveBaseDps = config.getParameter("inactiveBaseDps")
  self.activeBaseDps = config.getParameter("activeBaseDps")
  self.inactiveDamageType = config.getParameter("inactiveDamageType")
  self.inactiveElementalType = config.getParameter("inactiveElementalType")
  self.activeElementalType = config.getParameter("activeElementalType")
  self.activeDamageType = config.getParameter("activeDamageType")
  self.inactiveEnergyUsage = config.getParameter("inactiveEnergyUsage")
  self.activeEnergyUsage = config.getParameter("activeEnergyUsage")

  self.active = false
  animator.setAnimationState("sword", "inactive")
  self.primaryAbility.animKeyPrefix = "inactive"
  self.primaryAbility.baseDps = self.inactiveBaseDps
  self.elementalType = self.inactiveElementalType
  self.primaryAbility.damageConfig.damageSourceKind = self.inactiveDamageType
  self.primaryAbility.energyUsage = self.inactiveEnergyUsage
  self.primaryAbility:computeDamageAndCooldowns()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)

  setActive(self.altAbility.active)
end

function uninit()
  self.weapon:uninit()
end

function setActive(active)
  if self.active ~= active then
    self.active = active
    if self.active then
      animator.setAnimationState("sword", "extend")
      self.primaryAbility.animKeyPrefix = "active"
      self.primaryAbility.baseDps = self.activeBaseDps
	    self.elementalType = self.activeElementalType
      self.weapon.elementalType = self.activeElementalType
	    self.primaryAbility.damageConfig.damageSourceKind = self.activeDamageType
	    self.primaryAbility.energyUsage = self.activeEnergyUsage
      self.primaryAbility:computeDamageAndCooldowns()
    else
      animator.setAnimationState("sword", "retract")
      self.primaryAbility.animKeyPrefix = "inactive"
      self.primaryAbility.baseDps = self.inactiveBaseDps
  	  self.elementalType = self.inactiveElementalType
      self.weapon.elementalType = self.inactiveElementalType
  	  self.primaryAbility.damageConfig.damageSourceKind = self.inactiveDamageType
  	  self.primaryAbility.energyUsage = self.inactiveEnergyUsage
      self.primaryAbility:computeDamageAndCooldowns()
    end
  end
end
