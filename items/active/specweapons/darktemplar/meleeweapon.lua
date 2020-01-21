require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"
require "/items/active/weapons/weapon.lua"

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  animator.setGlobalTag("directives", "")
  animator.setGlobalTag("bladeDirectives", "")

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAttack = getAltAbility()
  if secondaryAttack then
    self.weapon:addAbility(secondaryAttack)
  end

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  incorrectWeapon()
  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  if self.weapon.tickExplodingTimer then
    activeItem.setInstanceValue("killCount", 0)
  end
  incorrectWeapon(true)
  self.weapon:uninit()
end
