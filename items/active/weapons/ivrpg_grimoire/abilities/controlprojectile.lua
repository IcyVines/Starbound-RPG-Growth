require "/scripts/vec2.lua"
require "/scripts/util.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
  storage.projectiles = storage.projectiles or {}

  self.elementalType = self.elementalType or self.weapon.elementalType
  self.cooldownTime = 0.4
  self.cooldownTimer = self.cooldownTime / 2
  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
  self.stances = config.getParameter("stances")
  self.elementalConfig = config.getParameter("primaryAbility.elementalConfig", {})

  animator.setGlobalTag("chargeHue", "?multiply=" .. self.elementalConfig[self.elementalType].hue)
  activeItem.setCursor("/cursors/reticle5.cursor")
  activeItem.setScriptedAnimationParameter("rune", false)
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function ControlProjectile:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  --self:updateProjectiles()

  world.debugPoint(self:focusPosition(), "blue")

  animator.resetTransformationGroup("charge")
  local cursorPosition = activeItem.ownerAimPosition()
  local position = mcontroller.position()
  local difference = world.distance(cursorPosition, position)
  local frontal = {2.75, -1}--world.distance(self:focusPosition(), position)
  difference[1] = difference[1] * mcontroller.facingDirection()
  --frontal[1] = frontal[1] * mcontroller.facingDirection()
  --animator.translateTransformationGroup("charge", difference)
  animator.translateTransformationGroup("charge", frontal)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy")
    and not self.abilityActive
    and not (self.cooldownTimer > 0) then

    self:setState(self.charge)
  end

  self.cooldownTimer = math.max(self.cooldownTimer - dt, 0)

end

function ControlProjectile:charge()
  self.weapon:setStance(self.stances.charge)

  animator.playSound("bookopen")
  animator.setAnimationState("bookState", "open")
  animator.setAnimationState("charge", "charging")

  local chargeTimer = self.stances.charge.duration
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  if chargeTimer <= 0 then
    self:setState(self.charged)
  else
    self:setState(self.discharge)
  end
end

function ControlProjectile:charged()
  self.weapon:setStance(self.stances.charged)

  animator.setAnimationState("bookState", "charging")
  math.randomseed(os.time())

  local image = "/items/active/weapons/ivrpg_grimoire/generated/runes/"
  local color = self.elementalConfig[self.elementalType].color

  local particle = {
    type = "textured",
    image = image .. "1.png",
    size = 1,
    color = copy(color),
    fade = 0.9,
    initialVelocity = {0.0, 1.0},
    finalVelocity = {0.0, 0.0},
    rotation = 0,
    angularVelocity = 0,
    timeToLive = 0.5,
    destructionAction = "shrink",
    destructionTime = 0.5,
    layer = "front",
    variance = {
      initialVelocity = {0.5, 0.5},
      size = 0.2,
      rotation = 10,
      angularVelocity = 10,
      position = {0.5, 0.75}
    },
    position = self:focusPosition()
  }

  local targetValid
  local spawnTime = 0.4
  local runeTimer = spawnTime
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    targetValid = self:targetValid(activeItem.ownerAimPosition())
    --activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")
    if runeTimer >= spawnTime then
      particle.position = self:focusPosition()
      particle.image = image .. tostring(math.random(1,7)) .. ".png"
      activeItem.setScriptedAnimationParameter("rune", particle)
      runeTimer = 0
    else
      activeItem.setScriptedAnimationParameter("rune", false)
      runeTimer = runeTimer + self.dt
    end
    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end
  self.abilityActive = true
  self:setState(self.discharge)
end

function ControlProjectile:discharge()
  self.weapon:setStance(self.stances.discharge)
  activeItem.setScriptedAnimationParameter("rune", false)

  animator.stopAllSounds("bookopen")
  activeItem.setCursor("/cursors/reticle5.cursor")
  animator.setAnimationState("charge", "off")
  animator.setAnimationState("bookState", "idle")

  if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor) and self.abilityActive then
    animator.playSound(self.elementalType.."activate")
    self:createProjectiles()
  else
    animator.playSound("bookclose")
    util.wait(self.stances.discharge.duration / 2, function(dt)
      status.setResourcePercentage("energyRegenBlock", 1.0)
    end)
    self.abilityActive = false
    self.cooldownTimer = self.cooldownTime
    return
  end

  util.wait(self.stances.discharge.duration, function(dt)
    status.setResourcePercentage("energyRegenBlock", 1.0)
  end)

  -- Change this to be dependent on the ability. Some abilities are instant cast. Some are not!
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    status.setResourcePercentage("energyRegenBlock", 1.0)
    coroutine.yield()
  end

  self.cooldownTimer = self.cooldownTime
  self.abilityActive = false
  --self:killProjectiles()
  --self:setState(self.cooldown)
end

function ControlProjectile:targetValid(aimPos)
  local focusPos = self:focusPosition()
  return world.magnitude(focusPos, aimPos) <= self.maxCastRange
      and not world.lineTileCollision(mcontroller.position(), focusPos)
      and not world.lineTileCollision(focusPos, aimPos)
end

function ControlProjectile:createProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local fireDirection = world.distance(aimPosition, self:focusPosition())[1] > 0 and 1 or -1
  local pOffset = {fireDirection * (self.projectileDistance or 0), 0}
  local basePos = activeItem.ownerAimPosition()

  local pCount = self.projectileCount or 1

  local pParams = copy(self.projectileParameters)
  pParams.power = self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
  pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

  for i = 1, pCount do
    local projectileId = world.spawnProjectile(
        self.projectileType,
        vec2.add(basePos, pOffset),
        activeItem.ownerEntityId(),
        pOffset,
        false,
        pParams
      )

    if projectileId then
      table.insert(storage.projectiles, projectileId)
      world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
    end

    pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
  end
end

function ControlProjectile:focusPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("grimoire", "focalPoint")))
end

-- give all projectiles a new aim position and let those projectiles return one or
-- more entity ids for projectiles we should now be tracking
function ControlProjectile:updateProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local newProjectiles = {}
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      local projectileResponse = world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
      if projectileResponse:finished() then
        local newIds = projectileResponse:result()
        if type(newIds) ~= "table" then
          newIds = {newIds}
        end
        for _, newId in pairs(newIds) do
          table.insert(newProjectiles, newId)
        end
      end
    end
  end
  storage.projectiles = newProjectiles
end

function ControlProjectile:killProjectiles()
  for _, projectileId in pairs(storage.projectiles) do
    if world.entityExists(projectileId) then
      world.sendEntityMessage(projectileId, "kill")
    end
  end
end

function ControlProjectile:reset()
  self.weapon:setStance(self.stances.idle)
  animator.setAnimationState("bookState", "idle")
  animator.setAnimationState("charge", "off")
  activeItem.setScriptedAnimationParameter("rune", false)
  activeItem.setCursor("/cursors/reticle5.cursor")
  self.abilityActive = false
end

function ControlProjectile:uninit(weaponUninit)
  self:reset()
  if weaponUninit then
    self:killProjectiles()
  end
end
