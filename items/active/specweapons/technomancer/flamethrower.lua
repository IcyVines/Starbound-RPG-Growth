require "/items/active/weapons/ranged/gunfire.lua"
require "/scripts/ivrpgutil.lua"

FlamethrowerAttack = GunFire:new()

function FlamethrowerAttack:init()
  GunFire.init(self)
  self.projectileNames = config.getParameter("primaryAbility.projectileNames", {})
  self.elementalTypes = config.getParameter("elementalTypes", {})
  self.active = false
  self.ammoIndex = config.getParameter("ammoIndex", 1)
  self.lastIndex = config.getParameter("lastIndex", 1)
  self.elementalType = self.elementalTypes[ammoIndex]
  animator.setAnimationState("elementalType", self.ammoIndex)
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function FlamethrowerAttack:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
  self.shiftHeld = shiftHeld

  if fireMode == "primary" and self.weapon.currentAbility == self and not self.switching then
    if not self.active then self:activate() end
  elseif self.active then
    self:deactivate()
  end

  if fireMode == "alt" and not self.weapon.currentAbility and not self.active then
    self.switching = true
    self:setState(self.switch)
  end

  incorrectWeapon()
end

function FlamethrowerAttack:muzzleFlash()
  --disable normal muzzle flash
end

function FlamethrowerAttack:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)
  
self.hipower = status.statPositive("ivrpgucomnihp")
projectileType = self.projectileNames[self.ammoIndex or 1] or "ivrpgnova"
if self.hipower then
  projectileType = projectileType .. "throwerhipower"
else
  projectileType = projectileType .. "thrower"
end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
end

function FlamethrowerAttack:activate()
  self.active = true
  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)
end

function FlamethrowerAttack:deactivate()
  self.active = false
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
  animator.playSound("fireEnd")
end

function FlamethrowerAttack:uninit()
  incorrectWeapon(true)
end

function FlamethrowerAttack:switch()
  if self.shiftHeld then
    local newIndex = self.lastIndex
    self.lastIndex = self.ammoIndex
    self.ammoIndex = newIndex
  else
    self.ammoIndex = (self.ammoIndex % #self.projectileNames) + 1
    self.lastIndex = 1
  end

  activeItem.setInstanceValue("lastIndex", self.lastIndex)
  activeItem.setInstanceValue("ammoIndex", self.ammoIndex)
  self.elementalType = self.elementalTypes[self.ammoIndex]
  activeItem.setInstanceValue("elementalType", self.elementalTypes[self.ammoIndex])
  animator.setAnimationState("elementalType", self.ammoIndex)
  local tooltipFields = {damageKindImage = "/interface/elements/"..self.elementalType..".png"}
  activeItem.setInventoryIcon("/items/active/specweapons/technomancer/omniathrower_" .. self.elementalType .. ".png")
  activeItem.setInstanceValue("tooltipFields", tooltipFields)
  animator.playSound("switchElement")

  self.weapon:setStance(self.stances.switch)
  util.wait(self.stances.switch.duration)
  self.switching = false
end
