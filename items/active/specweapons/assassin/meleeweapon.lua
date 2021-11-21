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
  incorrectWeapon()
end

function uninit()
  incorrectWeapon(true)
  self.weapon:uninit()
end

function Weapon:updateAim()
  for _,group in pairs(self.transformationGroups) do
    animator.resetTransformationGroup(group.name)
    animator.translateTransformationGroup(group.name, group.offset)
    animator.rotateTransformationGroup(group.name, group.rotation, group.rotationCenter)
    animator.translateTransformationGroup(group.name, self.weaponOffset)
    animator.rotateTransformationGroup(group.name, self.relativeWeaponRotation, self.relativeWeaponRotationCenter)
  end

  animator.rotateTransformationGroup("swoosh", -math.pi / 4)
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.aimOffset, activeItem.ownerAimPosition())

  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  elseif self.stance.aimAngle then
    self.aimAngle = self.stance.aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  local isPrimary = activeItem.hand() == "primary"
  if isPrimary then
    -- primary hand weapons should set their aim direction whenever they can be flipped,
    -- unless paired with an alt hand that CAN'T flip, in which case they should use that
    -- weapon's aim direction
    if self.stance.allowFlip then
      if activeItem.callOtherHandScript("dwDisallowFlip") then
        local altAimDirection = activeItem.callOtherHandScript("dwAimDirection")
        if altAimDirection then
          self.aimDirection = altAimDirection
        end
      else
        self.aimDirection = aimDirection
      end
    end
  elseif self.stance.allowFlip then
    -- alt hand weapons should be slaved to the primary whenever they can be flipped
    local primaryAimDirection = activeItem.callOtherHandScript("dwAimDirection")
    if primaryAimDirection then
      self.aimDirection = primaryAimDirection
    else
      self.aimDirection = aimDirection
    end
  end

  activeItem.setFacingDirection(self.aimDirection)

  activeItem.setFrontArmFrame(self.stance.frontArmFrame)
  activeItem.setBackArmFrame(self.stance.backArmFrame)
end