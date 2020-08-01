require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/ivrpgutil.lua"

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  animator.setGlobalTag("directives", "")
  animator.setGlobalTag("bladeDirectives", "")

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  self.primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(self.primaryAbility)

  local secondaryAttack = getAltAbility()
  if secondaryAttack then
    self.weapon:addAbility(secondaryAttack)
  end

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)

  setElement(self.primaryAbility.elementalType)
  incorrectWeapon()
end

function setElement(element)
  if self.elementalType ~= element then
    self.elementalType = element
    self.weapon.elementalType = element
    animator.setGlobalTag("elementalType", self.elementalType)
    self.primaryAbility.damageConfig.damageSourceKind = (self.elementalType ~= "physical" and self.elementalType or "") .. "broadsword"
    self.primaryAbility:computeDamageAndCooldowns()
  end
end

function uninit()
  incorrectWeapon(true)
  self.weapon:uninit()
end