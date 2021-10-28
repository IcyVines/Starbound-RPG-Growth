require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

ControlProjectile = WeaponAbility:new()

function ControlProjectile:init()
  storage.projectiles = storage.projectiles or {}

  self.elementalType = self.elementalType or self.weapon.elementalType
  self.cooldownTime = 0.4
  self.cooldownTimer = self.cooldownTime
  self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
  self.stances = config.getParameter("stances")
  self.elementalConfig = config.getParameter("elementalConfig", {})

  self.travelDirection = self.abilitySlot == "primary" and config.getParameter("primaryAbility.travelDirection") or config.getParameter("altAbility.travelDirection")
  self.spawnLocation = self.abilitySlot == "primary" and config.getParameter("primaryAbility.spawnLocation") or config.getParameter("altAbility.spawnLocation")
  self.chargeTimeModifier = self.abilitySlot == "primary" and config.getParameter("primaryAbility.chargeTimeModifier") or config.getParameter("altAbility.chargeTimeModifier")
  self.projectileOffset = self.abilitySlot == "primary" and config.getParameter("primaryAbility.projectileOffset", {0,0}) or config.getParameter("altAbility.projectileOffset", {0,0})
  self.behavior = self.abilitySlot == "primary" and config.getParameter("primaryAbility.behavior", "") or config.getParameter("altAbility.behavior", "")
  self.notDespawned = self.abilitySlot == "primary" and config.getParameter("primaryAbility.notDespawned") or config.getParameter("altAbility.notDespawned")
  self.elementalType = self.abilitySlot == "primary" and self.elementalType or config.getParameter("altElementalType")

  self.weapon.healOnHit = config.getParameter("primaryAbility.healOnHit")

  -- Greater Barrier
  self.shieldActive = false
  self.shieldFrameTimer = 0.2
  self.shieldFrame = 0
  self.shieldShattered = false

  -- Beam
  self.impactSoundTimer = 0
  self.transitionTimer = 0
  self.baseDamage = self.projectileParameters.baseDamage

  -- Mana Blade/Scythe
  self.followTimer = 0

  activeItem.setCursor("/cursors/reticle5.cursor")
  activeItem.setScriptedAnimationParameter("rune", false)
  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function ControlProjectile:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  local stopsAtCursor = self.behavior and string.find(self.behavior, "AfterCursor")

  -- Mana Blade/Scythe
  if stopsAtCursor and self.projectileId and self.followTimer > 0 then
    self.followTimer = math.max(self.followTimer - dt, 0)
    if self.followTimer == 0 and world.entityExists(self.projectileId) then
      if self.behavior == "followNearestAfterCursor" then world.sendEntityMessage(self.projectileId, "trigger", "follow") end
      if self.behavior == "releaseRadialAfterCursor" then world.sendEntityMessage(self.projectileId, "trigger", "release") end
    end
  end

  -- Normal Fire Transition
  world.debugPoint(self:focusPosition(), "blue")
  --animator.setAnimationRate(1/(self.chargeTimeModifier or 1))
  --sb.logInfo(sb.printJson(self.chargeTimeModifier))
  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not status.resourceLocked("energy")
    and not self.abilityActive
    and not (self.cooldownTimer > 0)
    and not (self.fireMode == "alt" and (self.shieldShattered or self.shieldActive)) then
    self.transitionTimer = 0
    self:setState(self.charge)
  end

  self.cooldownTimer = math.max(self.cooldownTimer - dt, 0)

  -- Nosferatu
  if self.nosferatuActive and world.entityExists(self.nosferatuActive) then
    world.sendEntityMessage(self.nosferatuActive, "addEphemeralEffect", "ivrpg_nosferatu", 0.5)
    activeItem.setScriptedAnimationParameter("nosferatu", {frame = self.nosferatuFrame, position = {mcontroller.xPosition(), mcontroller.yPosition()}, monsterPos = world.entityPosition(self.nosferatuActive)})
    self.nosferatuFrameTimer = self.nosferatuFrameTimer - dt
    if self.nosferatuFrameTimer <= 0 then
      self.nosferatuFrame = (self.nosferatuFrame + 1) % 20
      self.nosferatuFrameTimer = 0.05
    end
  else
    activeItem.setScriptedAnimationParameter("nosferatu", false)
    self.nosferatuActive = false
  end

  -- Greater Barrier
  if self.shieldActive then
    local mod = ".png:"
    if status.resource("shieldStamina") <= 0.5 then
      mod = "_cracked.png:"
    end
    activeItem.setScriptedAnimationParameter("barrier", {frame = self.shieldFrame, position = {mcontroller.xPosition(), mcontroller.yPosition() - 0.75}, modifier = mod})
    self.shieldFrameTimer = self.shieldFrameTimer - dt
    if self.shieldFrameTimer <= 0 then
      self.shieldFrame = (self.shieldFrame + 1) % 8
      self.shieldFrameTimer = 0.2
    end

    if not status.resourcePositive("shieldStamina") then
      self.shieldActive = false
      self.shieldShattered = 0
      animator.playSound("earthbarrierbreak")
      self.shieldFrameTimer = 0.1
    end
  elseif self.shieldShattered then
    local mod = "_shatter.png:"
    activeItem.setScriptedAnimationParameter("barrier", {frame = self.shieldShattered, position = {mcontroller.xPosition(), mcontroller.yPosition() - 0.75}, modifier = mod})
    self.shieldFrameTimer = self.shieldFrameTimer - dt
    if self.shieldFrameTimer <= 0 then
      self.shieldShattered = (self.shieldShattered + 1) % 7
      self.shieldFrameTimer = 0.3/7
      if self.shieldShattered == 0 then
        self.shieldShattered = false
        self.weapon:destroyBarrier()
      end
    end
  end

  -- Implosion
  if self.customPhysics and self.customPhysics.time > 0 then
    local targetIds = enemyQuery(activeItem.ownerAimPosition(), self.customPhysics.radius or 5, {}, activeItem.ownerEntityId(), true)
    if targetIds then
      for _,id in ipairs(targetIds) do
        if self.customPhysics.physics == "pull" and world.entityExists(id) then
          world.sendEntityMessage(id, "setVelocity", vec2.mul(vec2.sub(self.customPhysics.position, world.entityPosition(id)), 5))
        end
      end
    end
    self.customPhysics.time = self.customPhysics.time - dt
    if self.customPhysics.time <= 0 then self.customPhysics = false end
  end
end

function ControlProjectile:charge()
  self.weapon:setStance(self.stances.charge)
  animator.setGlobalTag("chargeHue", "?multiply=" .. self.elementalConfig[self.elementalType].hue)
  animator.playSound("bookopen")
  animator.setAnimationRate(1/(self.chargeTimeModifier or 1))
  animator.setAnimationState("bookState", "open")
  animator.setAnimationState("charge", "charging")

  local chargeTimer = self.stances.charge.duration * (self.chargeTimeModifier or 1)
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    self:moveChargePosition()

    coroutine.yield()
  end

  if chargeTimer <= 0 then
    self:setState(self.charged)
  else
    self:setState(self.discharge)
  end
end

function ControlProjectile:moveChargePosition()
  animator.resetTransformationGroup("charge")
  local cursorPosition = activeItem.ownerAimPosition()
  local position = mcontroller.position()
  if mcontroller.crouching() then position[2] = position[2] - 1 end
  local difference = world.distance(cursorPosition, position)
  local frontal = {3.125, 1.125}--world.distance(self:focusPosition(), position)
  difference[1] = difference[1] * mcontroller.facingDirection()
  --frontal[1] = frontal[1] * mcontroller.facingDirection()
  animator.translateTransformationGroup("charge", self.spawnLocation == "atCursor" and difference or frontal)
end

function ControlProjectile:charged()
  self.weapon:setStance(self.stances.charged)

  animator.setAnimationRate(1)
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
    activeItem.setCursor(targetValid and "/items/active/weapons/ivrpg_grimoire/cursor/reticle.cursor" or "/cursors/reticle5.cursor")

    self:moveChargePosition()

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

  animator.setAnimationRate(1)
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

  self.cooldownTimer = self.cooldownTime
  self.abilityActive = false
end

function ControlProjectile:spawnBeam()
  self.timer = 0
  self.spawnPosition = activeItem.ownerAimPosition()
  self.randomDirection = math.random(-2,2)
  world.spawnProjectile("ivrpgraptureholygate", self.spawnPosition, activeItem.ownerEntityId(), {0.1 * self.randomDirection, -1}, false, {timeToLive = 0.8, speed = 0})
  self.reap = true
  util.wait(0.5, function()
    local params = {curveDirection = self.randomDirection, timeToLive = 0.3, speed = 70}
    if self.reap then
      params.actionOnReap = {{action = "projectile", type = "ivrpgraptureholygate", config = {timeToLive = 0.5}}}
      self.reap = false
    end
    world.spawnProjectile("ivrpgrapturebeam", self.spawnPosition, activeItem.ownerEntityId(), {0.1 * self.randomDirection, -1}, false, params)
  end)
end

function ControlProjectile:targetValid(aimPos)
  local focusPos = self:focusPosition()
  return world.magnitude(focusPos, aimPos) <= self.maxCastRange
      and not world.lineTileCollision(mcontroller.position(), focusPos)
      and not (self.spawnLocation == "atCursor" and world.lineTileCollision(focusPos, aimPos))
end

function ControlProjectile:createProjectiles()
  local aimPosition = activeItem.ownerAimPosition()
  local distanceTo = world.distance(aimPosition, self:focusPosition())
  local fireDirection = distanceTo[1] > 0 and 1 or -1
  local pOffset = {fireDirection * (self.projectileDistance or 0), 0}
  local basePos = self.spawnLocation == "atCursor" and activeItem.ownerAimPosition() or self:focusPosition()
  local basePos = vec2.add(basePos, self.projectileOffset)
  local pCount = self.projectileCount or 1
  local pParams = copy(self.projectileParameters)

  if pParams.shieldParameters then
    pParams.shieldParameters.power = (pParams.shieldParameters.baseDamage or 0) * config.getParameter("damageLevelMultiplier")
    pParams.shieldParameters.health = (pParams.shieldParameters.health or 10) * config.getParameter("damageLevelMultiplier")
    self.weapon:createBarrier(pParams.shieldParameters)
    self.shieldActive = true
    self.shieldFrame = 0
    self.shieldFrameTimer = 0.2
    return
  end

  if pParams.nosferatu then
    self:findNosferatuTarget()
    self.nosferatuFrame = 0
    self.nosferatuFrameTimer = 0.05
    return
  end

  local stopsAtCursor = self.behavior and string.find(self.behavior, "AfterCursor")

  if self.travelDirection == "atCursor" then
    local tTL = vec2.mag(distanceTo) / (pParams.speed or 1)
    pParams.timeToLive = (pParams.timeToLive or 0) + tTL
    if stopsAtCursor then
      self.followTimer = tTL
    end
  end

  if pParams.aimDirection then
    pParams.aimDirection = distanceTo
  end

  pParams.power = self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
  pParams.powerMultiplier = activeItem.ownerPowerMultiplier()
  if pParams.actionOnTimeout then
    self:fireElementalPillar(pParams)
    return
  elseif pParams.portal then
    self:fireEruption(pParams)
    return
  end

  for i = 1, pCount do
    local projectileId = world.spawnProjectile(
        self.projectileType,
        vec2.add(basePos, pOffset),
        activeItem.ownerEntityId(),
        self.travelDirection == "none" and pOffset or distanceTo,
        false,--(self.behavior == "followPlayer") or false,
        pParams
      )

    if projectileId then
      table.insert(storage.projectiles, projectileId)
      world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
    end

    if pParams.spread then
      pOffset = {0, 0}
      pParams.spread[1] = pParams.spread[1] * -1
      pOffset = vec2.add(pOffset, pParams.spread)
      self.lightning = basePos
    elseif pParams.rapid then

    else
      pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
    end

    if stopsAtCursor then
      self.projectileId = projectileId
    end
    
  end

  if pParams.customPhysics then
    pParams.customPhysics.position = activeItem.ownerAimPosition()
    self.customPhysics = pParams.customPhysics
  end
end

function ControlProjectile:findNosferatuTarget()
  local targets = enemyQuery(activeItem.ownerAimPosition(), 3, {}, activeItem.ownerEntityId(), false)
  if targets then
    for _,id in ipairs(targets) do
      if world.entityExists(id) then
        self.nosferatuActive = id
      end
    end
  end
end

function ControlProjectile:focusPosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("grimoire", "focalPoint")))
end

function ControlProjectile:beamOffset()
  return animator.partPoint("grimoire", "focalPoint")
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
  animator.setAnimationRate(1)
end

function ControlProjectile:uninit(weaponUninit)
  self:reset()
  if weaponUninit then
    --self:killProjectiles()
    self.weapon:destroyBarrier()
    activeItem.setScriptedAnimationParameter("nosferatu", false)
  end
end

function Weapon:destroyBarrier()
  activeItem.setShieldPolys({})
  activeItem.setDamageSources({})
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
  animator.setAnimationState("barrier", "off")
  activeItem.setScriptedAnimationParameter("barrier", false)
  status.clearPersistentEffects("ivrpg_greaterbarrier")
end

function ControlProjectile:fireEruption(params)
  local offsets = params.offsets[self.elementalType]
  local portal = params.portal
  local portalOffsets = params.portalOffsets[self.elementalType]
  local position = mcontroller.position()
  local direction = params.directions[self.elementalType]

  for index,offset in ipairs(offsets) do
    local newOffset = vec2.add(position, offset)
    if portalOffsets then
      world.spawnProjectile(portal, vec2.add(newOffset, portalOffsets[index]), activeItem.ownerEntityId(), {0,0}, false, {})
    end
    world.spawnProjectile(self.projectileType, newOffset, activeItem.ownerEntityId(), direction[index], false, params)
  end
end

-- Helper functions
function ControlProjectile:fireElementalPillar(params)
  local count = 0
  local impactPositions = 0
  local pos = activeItem.ownerAimPosition()
  local dir = mcontroller.facingDirection()
  while impactPositions < 5 and count < 15 do
    local impactPosition = self:impactPosition(params, pos, dir, impactPositions > 0 and 2 or 0)
    if impactPosition then
      local projectileCount = (impactPositions + 4)
      if self.elementalType ~= "holy" and self.elementalType ~= "nova" then
        animator.setSoundVolume(self.elementalType.."impact", 0.25)
      else
        animator.setSoundVolume(self.elementalType.."impact", 0.75)
      end
      animator.playSound(self.elementalType.."impact")
      local dir = mcontroller.facingDirection()
      for i = 0, (projectileCount - 1) do
        params.timeToLive = i * 0.02
        params.actionOnTimeout[1].config.timeToLive = params.pillarDuration - (2 * params.timeToLive)
        local position = vec2.add(impactPosition, {0, i})
        if not world.pointTileCollision(position, {"Null", "Block", "Dynamic", "Slippery"}) then
          world.spawnProjectile("pillarspawner", position, activeItem.ownerEntityId(), {dir, 0}, false, params)
        else
          return
        end
      end
      impactPositions = impactPositions + 1
      pos = impactPosition
      util.wait(0.2)
    end
    count = count + 1
  end
end

function ControlProjectile:impactPosition(params, pos, dir, offset)
  --local pos = activeItem.ownerAimPosition()
  --local randX = (math.random() * 2 - 1) * params.pillarDistance[2] + params.pillarDistance[1]
  local startLine = vec2.add(pos, {dir * offset, params.pillarVerticalTolerance[1]})
  local endLine = vec2.add(pos, {dir * offset, params.pillarVerticalTolerance[2]})

  local blocks = world.collisionBlocksAlongLine(startLine, endLine, {"Null", "Block", "Dynamic", "Slippery"})
  if #blocks > 0 then
    if world.lineCollision(vec2.add(pos, {0, 2}), vec2.add(blocks[#blocks], {0.5, 1.5}), {"Null", "Block", "Dynamic", "Slippery"}) then return end
    return vec2.add(blocks[#blocks], {0.5, 1.5})
  end
end