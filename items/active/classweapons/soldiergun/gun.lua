require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()
  self.armTimer = 0
  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setFacingDirection(aimDirection)
  if fireMode == "alt" or fireMode == "primary" then
    self.armTimer = 1
  else
    self.armTimer = math.max(self.armTimer - dt, 0)
  end
  activeItem.setTwoHandedGrip(self.armTimer > 0)
end

function uninit()
  self.weapon:uninit()
end
