require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.class = world.entityCurrency(activeItem.ownerEntityId(), "classtype") or 4
  animator.setGlobalTag("paletteSwaps", self.class .. ".png")
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
  self.weapon:update(dt, fireMode, shiftHeld)
  self.class = world.entityCurrency(activeItem.ownerEntityId(), "classtype") == 1 and 1 or 4
  animator.setGlobalTag("paletteSwaps", self.class .. ".png")
  incorrectWeapon()
end

function uninit()
  self.weapon:uninit()
  incorrectWeapon(true)
end
