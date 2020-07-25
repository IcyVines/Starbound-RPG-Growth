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

  self.inactiveBaseDps = config.getParameter("inactiveBaseDps")
  self.activeBaseDps = config.getParameter("activeBaseDps")
  self.inactiveDamageType = config.getParameter("inactiveDamageType")
  self.inactiveElementalType = config.getParameter("inactiveElementalType")
  self.activeElementalType = config.getParameter("activeElementalType")
  self.activeDamageType = config.getParameter("activeDamageType")
  self.inactiveEnergyUsage = config.getParameter("inactiveEnergyUsage")
  self.activeEnergyUsage = config.getParameter("activeEnergyUsage")

  self.active = false
  --animator.setAnimationState("sword", "inactive")
  --self.primaryAbility.animKeyPrefix = "inactive"
  self.primaryAbility.baseDps = self.inactiveBaseDps
  self.elementalType = self.inactiveElementalType
  self.primaryAbility.damageConfig.damageSourceKind = self.inactiveDamageType
  self.primaryAbility.energyUsage = self.inactiveEnergyUsage
  self.primaryAbility:computeDamageAndCooldowns()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)

  setActive(self.primaryAbility.active)
  incorrectWeapon()
end

function setActive(active)
  if self.active ~= active then
    self.active = active
    if self.active then
      animator.setGlobalTag("activeDirective", "active")
      animator.setLightActive("glow", true)
      self.primaryAbility.animKeyPrefix = "active"
      self.primaryAbility.baseDps = self.activeBaseDps
      self.elementalType = self.activeElementalType
      self.weapon.elementalType = self.activeElementalType
      self.primaryAbility.damageConfig.damageSourceKind = self.activeDamageType
      self.primaryAbility.energyUsage = self.activeEnergyUsage
      self.primaryAbility:computeDamageAndCooldowns()
    else
      animator.setGlobalTag("activeDirective", "")
      animator.setLightActive("glow", false)
      self.primaryAbility.animKeyPrefix = ""
      self.primaryAbility.baseDps = self.inactiveBaseDps
      self.elementalType = self.inactiveElementalType
      self.weapon.elementalType = self.inactiveElementalType
      self.primaryAbility.damageConfig.damageSourceKind = self.inactiveDamageType
      self.primaryAbility.energyUsage = self.inactiveEnergyUsage
      self.primaryAbility:computeDamageAndCooldowns()
    end
  end
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

  animator.scaleTransformationGroup("weapon", {0.25, 0.25})

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