require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.elementConfig = config.getParameter("elementConfig", {})

  -- General variables
  self.id = entity.id()
  self.elementMod = status.statusProperty("ivrpgAttunement", 1)
  self.elementList = self.elementConfig.elements
  self.element = self.elementList[self.elementMod]
  self.statusList = self.elementConfig.statuses
  self.borderList = self.elementConfig.fades
  self.primaryList = {flameBurst, icicleRush, arcFlash}
  self.action2List = {updateFireStream, updateIceBarrier, activateJolt}
  self.newMod = {2,3,1}
  self.directives = ""
  self.twoHandedCategories = config.getParameter("twoHandedCategories", {})
  self.cooldownTimer = 0
  self.cooldownTimerS = 0
  self.cooldownTimerU = 0
  self.shiftHeld = false
  self.weaveBonus = 1

  -- For increasing Attunement
  self.levelList = status.statusProperty("ivrpgAttunementLevels", {1,1,1})
  self.percentList = status.statusProperty("ivrpgAttunementPercent", {0,0,0})
  self.level = 1
  animator.setAnimationState("gauge", self.element)
  animator.playSound(self.element .. "Activate")
  _, self.damageGivenUpdate = status.inflictedDamageSince()
  self.killTimer = 0
  --[[
  Basic = 1
  Decent = 2-3
  Great = 4-5
  Chaos = 6-7
  ]]

  -- Icicle Rush specific variables
  self.icicleRushDirection = nil
  self.icicleRushTimer = 0
  self.icicleRushTime = 0.35
  self.icicleRushMovement = 0.25
  self.icicleRushSpeed = 40
  self.icicleRushHop = false
  message.setHandler("ivrpgElementressIcicleRush", function()
    self.icicleRushHop = true
  end)

  -- Jolt specific variables
  self.joltTimer = 0
  self.transformFadeTimer = 0
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.joltPoly = config.getParameter("joltCollisionPoly", {})
  self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}
  self.active = false

  -- Arc Flash specific variables
  self.overchargeTimer = 0
  self.overchargeTime = 15
  message.setHandler("ivrpgElementressOvercharge", function(_, _)
    animator.playSound("recharge")
    self.overchargeTimer = self.overchargeTime
  end)

  -- Ice Barrier specific variables
  self.barrierProjectiles = {}
  self.barrierFacing = 1
  self.iceActive = false

  -- Flamethrower specific variables
  self.fireTime = 0.065
  self.fireTimer = 0
  self.fireActive = false

  Bind.create("specialTwo", toggle)
  Bind.create("primaryFire", action1, true)
  Bind.create("altFire", action1alt, true)
end

function toggle()
  if self.active or not self.shiftHeld then return end
  self.elementMod = self.newMod[self.elementMod]
  self.element = self.elementList[self.elementMod]
  animator.setAnimationState("gauge", self.element)
  animator.playSound(self.element .. "Activate")
  cooldowns(0.2)
end

function uninit()
  tech.setParentDirectives()
  animator.stopAllSounds("flamethrowerStart")
  animator.stopAllSounds("flamethrowerLoop")
  storePosition()
  deactivate()
  status.clearPersistentEffects("ivrpgattune")
  status.setStatusProperty("ivrpgAttunementElement", false)
  status.clearPersistentEffects("ivrpg_elementressIcicleRush")
end

--[[

Special Fire: Explosion
Within the magma zone, enemies take constant damage. While the zone exists, bursts of flame build within and are ejected when finished: these bursts explode on contact.

Special Electric: Thunder
Call down a quick torrent of massive thunderbolts. Enemies hit by these bolts instantly die if they have less than 50% remaining health.

]]

--15,30, 55,80, 90,100

function update(args)
  status.setPersistentEffects("ivrpgattune", {
    {stat = self.element .. "StatusImmunity", amount = 1},
    {stat = self.element .. "Resistance", amount = 3},
    {stat = "lavaImmunity", amount = self.element == "fire" and 1 or 0},
    {stat = "invulnerable", amount = self.active and 1 or 0}
  })

  if self.percentList[self.elementMod] < 15 then
    self.level = 1
    self.levelList[self.elementMod] = 1
  elseif self.percentList[self.elementMod] < 30 then
    self.level = 2
    self.levelList[self.elementMod] = 2
  elseif self.percentList[self.elementMod] < 55 then
    self.level = 2
    self.levelList[self.elementMod] = 3
  elseif self.percentList[self.elementMod] < 80 then
    self.level = 3
    self.levelList[self.elementMod] = 4
  elseif self.percentList[self.elementMod] < 90 then
    self.level = 3
    self.levelList[self.elementMod] = 5
  elseif self.percentList[self.elementMod] < 100 then
    self.level = 4
    self.levelList[self.elementMod] = 6
  elseif self.percentList[self.elementMod] >= 100 then
    self.level = 4
    self.levelList[self.elementMod] = 7
  end

  status.setStatusProperty("ivrpgAttunementElement", self.element)
  status.setStatusProperty("ivrpgAttunement", self.elementMod)
  status.setStatusProperty("ivrpgAttunementLevels", self.levelList)
  status.setStatusProperty("ivrpgAttunementPercent", self.percentList)

  animator.setGlobalTag(self.element.."Mod", tostring(self.levelList[self.elementMod]))

  self.weaveMod = status.stat("ivrpgelementalweave")
  self.weaveBonus = (self.weaveMod == self.elementMod) and 1.5 or 1

  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.specialHeld = args.moves["special2"]
  self.hDirection = args.moves["left"] and -1 or (args.moves["right"] and 1 or 0)
  self.vDirection = args.moves["up"] and 1 or (args.moves["down"] and -1 or 0)

  if self.specialHeld and not (status.statPositive("activeMovementAbilities") and not status.statPositive("activeMovementAbilitiesJolt")) and self.cooldownTimerS == 0 and not self.shiftHeld and not status.resourceLocked("energy") then
    self.action2List[self.elementMod]()
  else
    if self.fireActive then
      animator.playSound("flamethrowerEnd")
    end
    self.fireActive = false
    killIceBarrier()
  end
  
  if self.element ~= "ice" or (status.resourceLocked("energy") and self.iceActive) then
    killIceBarrier()
  end

  if self.element ~= "fire" or not self.fireActive or (status.resourceLocked("energy") and self.fireActive) then
    animator.stopAllSounds("flamethrowerStart")
    animator.stopAllSounds("flamethrowerLoop")
    if self.fireActive then
      animator.playSound("flamethrowerEnd")
      self.fireActive = false
    end
  end

  animator.setGlobalTag("elementMod", self.element)
  animator.setAnimationState("overcharge", self.overchargeTimer > 0 and "on" or "off")
  self.overchargeTimer = math.max(0, self.overchargeTimer - args.dt)

  if self.icicleRushTimer > 0 then
    if self.icicleRushHop then
      mcontroller.setYVelocity(20)
      mcontroller.setXVelocity(-self.icicleRushDirection * self.icicleRushSpeed / 2)
      animator.playSound("icicleRushHop")
      tech.setParentState()
      self.icicleRushHop = false
      self.icicleRushTimer = 0
    elseif self.icicleRushTimer < self.icicleRushMovement then
      mcontroller.setVelocity({self.icicleRushDirection * self.icicleRushSpeed, 0})
      tech.setParentState("duck")
      status.setPersistentEffects("ivrpg_elementressIcicleRush", {
        {stat = "activeMovementAbilities", amount = 1},
        {stat = "physicalResistance", amount = 3},
        {stat = "grit", amount = 1}
      })
    end
    self.icicleRushTimer = math.max(0, self.icicleRushTimer - args.dt)
  else
    status.clearPersistentEffects("ivrpg_elementressIcicleRush")
    self.icicleRushHop = false
    tech.setParentState()
  end

  self.fireTimer = self.fireTimer - self.dt
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.cooldownTimerS = math.max(0, self.cooldownTimerS - self.dt)
  self.cooldownTimerU = math.max(0, self.cooldownTimerU - self.dt)

  updateJolt()
  updateTransformFade(self.dt)

  updateDamageGiven()

  if self.killTimer <= 0 then
    lowerGauges()
  else
    self.killTimer = self.killTimer - self.dt
  end
end

function lowerGauges()
  for i=1,3 do
    local timeDecay = 6
    if self.weaveMod == i then timeDecay = timeDecay + 0.6 end
    if self.elementMod == i then timeDecay = timeDecay + 1.5 end
    self.percentList[i] = math.max(0, self.percentList[i] - self.dt / timeDecay)
  end
end

-- Required to update Attunement Level
function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > 0 and (notification.damageSourceKind == "ivrpg_elementress" .. self.element) then
        if notification.targetEntityId and world.entityDamageTeam(notification.targetEntityId) and (world.entityDamageTeam(notification.targetEntityId).type == "enemy" or world.entityDamageTeam(notification.targetEntityId).type == "pvp") then
          self.percentList[self.elementMod] = math.min(self.percentList[self.elementMod] + notification.damageDealt / 20, 100)
          self.killTimer = 5
        end
        if self.overchargeTimer > 0 then
          world.sendEntityMessage(notification.targetEntityId, "applySelfDamageRequest", "IgnoresDef", "ivrpg_elementresselectric", 2 * status.stat("powerMultiplier"), entity.id())
        end
      end
    end
  end
end

function aimDirection(inaccuracy)
  return vec2.rotate(world.distance(tech.aimPosition(), mcontroller.position()), sb.nrand(inaccuracy or 0, 0))
end
  
-- Check if the Primary Projectile can be fired.
function action1()
  if (self.cooldownTimer > 0 or self.active) or 
    world.entityHandItem(self.id, "primary")
    or status.statPositive("activeMovementAbilities") then return end
    if self.shiftHeld and self.cooldownTimerU == 0 and self.percentList[self.elementMod] >= 15 then
      -- If statement to check if element is Fire and Ultimate is used. Don't want to go through walls.
      self.primaryList[self.elementMod]()
    elseif not self.shiftHeld then
      if world.lineTileCollision(vec2.add(mcontroller.position(), {mcontroller.facingDirection()*4,0}), mcontroller.position(), {"Block", "Slippery", "Null", "Dynamic"}) then return end
        if status.overConsumeResource("energy", self.elementConfig.primaryCosts[self.elementMod][self.level] / self.weaveBonus) then
          self.primaryList[self.elementMod](true)
          cooldowns(1)
        end
    else
      return
    end
end

function ultimateCost()
  self.percentList[self.elementMod] = math.max(self.percentList[self.elementMod] - 15, 0)
  cooldowns(1)
  self.cooldownTimerU = 5
end

-- Check if Alt Hand is empty when Alt Fire is pressed.
function action1alt()
  if self.cooldownTimer > 0 or self.active or status.statPositive("activeMovementAbilities") then return end
  local itemConfig = ivrpgBuildItemConfig(self.id, "primary")
  if itemConfig and itemConfig.config and (itemConfig.config.twoHanded or self.twoHandedCategories[itemConfig.config.category]) then return end
  if not world.entityHandItem(self.id, "alt") then action1(true) end
end

-- Primary Fire
function flameBurst(standard)
  if standard then
    local params = getParams()
    world.spawnProjectile(self.elementConfig.primaryProjectiles[1], {mcontroller.xPosition(), mcontroller.yPosition() - 0.5}, self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, params)
  elseif vec2.mag(world.distance(tech.aimPosition(), mcontroller.position())) <= 30 and not world.lineTileCollision(tech.aimPosition(), mcontroller.position(), {"Block", "Slippery", "Null", "Dynamic"}) and status.overConsumeResource("energy", self.elementConfig.ultimateCosts[self.elementMod] / self.weaveBonus) then
    animator.playSound("fireChargeActivate")
    local projectile = self.elementConfig.ultimateProjectiles[1]
    if math.random() <= 0.5 then projectile = projectile .. "_2" end
    world.spawnProjectile(projectile, tech.aimPosition(), self.id, {0,0}, false, {
      power = self.elementConfig.ultimatePower[1], powerMultiplier = status.stat("powerMultiplier"), speed = 0, timeToLive = 10
    })
    ultimateCost()
  end
end

-- Primary Ice
function icicleRush(standard)
    if standard then
      self.icicleRushDirection = mcontroller.facingDirection()
      self.icicleRushTimer = self.icicleRushTime
      local params = getParams()
      animator.playSound("iceChargeActivate")
      world.spawnProjectile(self.elementConfig.primaryProjectiles[2], {mcontroller.xPosition(), mcontroller.yPosition()}, self.id, {self.icicleRushDirection, 0}, false, params)
    else
      glacialSpike()
    end
end

function glacialSpike()
  local nearbyEntities = {}
  local targets = enemyQuery(mcontroller.position(), 15, {includedTypes = {"creature"}}, self.id, false)
  if targets then
    for _,id in ipairs(targets) do
      if world.entityExists(id) then
        local pos = world.entityPosition(id)
        local distance = vec2.mag(world.distance(mcontroller.position(), pos))
        if not world.lineTileCollision(mcontroller.position(), pos, {"Block", "Slippery", "Null", "Dynamic"}) then
          table.insert(nearbyEntities, id)
        end
      end
    end
  end

  local positions = {}
  local params = {power = self.elementConfig.ultimatePower[2], powerMultiplier = status.stat("powerMultiplier"), statusEffects = { "ivrpgfreeze" }}
  if nearbyEntities and #nearbyEntities > 0 then
    for _,id in ipairs(nearbyEntities) do
      if #positions < 3 then
        local position = world.entityPosition(id)
        local groundPos = world.lineCollision(position, vec2.sub(position, {0, 4}), {"Block", "Slippery", "Null", "Dynamic"})
        if groundPos then
          table.insert(positions, groundPos)
        end
      end
    end
  end

  if #positions > 0 and status.overConsumeResource("energy", self.elementConfig.ultimateCosts[self.elementMod] / self.weaveBonus) then
    spawnGlacialSpike(positions, params)
  end
end

function spawnGlacialSpike(positions, params)
  animator.playSound("iceChargeActivate")
  for _,pos in ipairs(positions) do
    world.spawnProjectile(self.elementConfig.ultimateProjectiles[2], vec2.add(pos, {0, 3.5}), self.id, {0, 0}, false, params)
  end
  ultimateCost()
end

-- Primary Electric
function arcFlash(standard)
  if standard then
    local params = getParams()
    local count = self.elementConfig.primaryParameters[3][self.level].amount
    local direction = {1,0}
    animator.playSound("electricChargeActivate")
    for i=1,count do
      world.spawnProjectile(self.elementConfig.primaryProjectiles[3], {mcontroller.xPosition(), mcontroller.yPosition()}, self.id, direction, false, params)
      direction = vec2.rotate(direction, 2 * math.pi / count)
    end
  else
    ionicThunder()
  end
end

function ionicThunder()
  local nearbyEntities = {}
  local targets = enemyQuery(mcontroller.position(), 15, {includedTypes = {"creature"}}, self.id, false)
  if targets then
    for _,id in ipairs(targets) do
      if world.entityExists(id) then
        local pos = world.entityPosition(id)
        local distance = vec2.mag(world.distance(mcontroller.position(), pos))
        if not world.lineTileCollision(mcontroller.position(), pos, {"Block", "Slippery", "Null", "Dynamic"}) then
          table.insert(nearbyEntities, id)
        end
      end
    end
  end

  local positions = {}
  local params = {speed = 0, power = self.elementConfig.ultimatePower[3], powerMultiplier = status.stat("powerMultiplier"), statusEffects = { "ivrpgoverload" }}
  if nearbyEntities and #nearbyEntities > 0 then
    for _,id in ipairs(nearbyEntities) do
      local position = world.entityPosition(id)
      if #positions < 8 and not world.lineTileCollision(position, vec2.add(position, {0, 10}), {"Block", "Slippery", "Null", "Dynamic"}) then
        table.insert(positions, vec2.add(position, {0, 4}))
      end
    end
  end

  if #positions > 0 and status.overConsumeResource("energy", self.elementConfig.ultimateCosts[self.elementMod] / self.weaveBonus) then
    spawnIonicThunder(positions, params)
  end
end

function spawnIonicThunder(positions, params)
  animator.playSound("electricChargeActivate")
  for _,pos in ipairs(positions) do
    world.spawnProjectile(self.elementConfig.ultimateProjectiles[3], pos, self.id, {0, 0}, false, params)
  end
  ultimateCost()
end

function getParams()
  local params = self.elementConfig.primaryParameters[self.elementMod][self.level]
  params.power = self.elementConfig.primaryPower[self.elementMod][self.level]
  params.powerMultiplier = status.stat("powerMultiplier")
  return params
end

-- Flame Thrower
function updateFireStream()
  if not self.fireActive then
    animator.playSound("flamethrowerStart")
    animator.playSound("flamethrowerLoop", -1)
  end
  self.fireActive = true
  if status.overConsumeResource("energy", self.dt * self.elementConfig.secondaryCosts[1] / self.weaveBonus) and self.fireTimer <= 0 then
    world.spawnProjectile(self.elementConfig.secondaryProjectiles[1], vec2.add(mcontroller.position(), {mcontroller.facingDirection() / 2, -0.25}), self.id, aimDirection(0.05), false, {
      power = self.elementConfig.secondaryPower[1], powerMultiplier = status.stat("powerMultiplier"), knockback = 5
    })
    self.fireTimer = self.fireTime
  end
end

-- Spawn Ice Barrier
function updateIceBarrier()
  local facingDirection = mcontroller.facingDirection()
  local position = mcontroller.position()
  local params = {powerMultiplier = status.stat("powerMultiplier"), power = self.elementConfig.secondaryPower[2] / 5, timeToLive = math.huge}
  if self.element == "ice" and #self.barrierProjectiles == 0 then 
    self.iceActive = true
    for i=-2,2 do
      local projectileId = world.spawnProjectile(self.elementConfig.secondaryProjectiles[2], vec2.add(position, {facingDirection * 3, i}), self.id, {facingDirection, 0}, true, params)
      if projectileId then table.insert(self.barrierProjectiles, projectileId) end
      projectileId = world.spawnProjectile(self.elementConfig.secondaryProjectiles[2], vec2.add(position, {-facingDirection * 3, i}), self.id, {-facingDirection, 0}, true, params)
      if projectileId then table.insert(self.barrierProjectiles, projectileId) end
    end
  elseif self.element ~= "ice" or not status.overConsumeResource("energy", self.dt * self.elementConfig.secondaryCosts[2] / self.weaveBonus) then
    killIceBarrier()
  end

end

-- Self explanatory
function killIceBarrier()
  for _,id in ipairs(self.barrierProjectiles) do
    world.sendEntityMessage(id, "kill")
  end
  self.barrierProjectiles = {}
  self.iceActive = false
end

-- Returns the aim vector perpendicular to the distance between the passed in vectors
function projectilePositionAndAim(from, to)
  local direction = vec2.norm(world.distance(to, from))
  local mid = {(from[1] + to[1]) / 2, (from[2] + to[2]) / 2}

  local toOwner = world.distance(mid, world.entityPosition(self.id))

  -- Out of the two possible perpendicular vectors, pick the one pointing horizontally away from the player
  local perp1 = {direction[2], -direction[1]}
  local perp2 = {-direction[2], direction[1]}
  direction = vec2.dot(perp1, toOwner) > 0 and perp1 or perp2

  return mid, direction
end

-- Checks whether player is currently Jolting
function updateJolt()
  if self.active then
    mcontroller.controlParameters({
      gravityEnabled = false,
      runningSuppressed = true,
      collisionPoly = self.joltPoly
    })
    status.setResourcePercentage("energyRegenBlock", 1.0)
    mcontroller.controlApproachVelocity(vec2.mul(self.joltDirection, 100), 1000)
    animator.setAnimationState("jolt", "on")
  else
    animator.setAnimationState("jolt", "off")
  end

  self.joltTimer = math.max(0, self.joltTimer - self.dt)
  
  if self.cooldownTimerS == 0 then
    if self.active then
      mcontroller.setVelocity({0,0})
      if self.joltTimer == 0 then attemptActivation() end
    end
  end
end

-- Calls attemptActivation if a movement key is held and there is energy left to Jolt.
function activateJolt()
  self.joltDirection = {self.hDirection, self.vDirection}
  if (self.hDirection ~= 0 or self.vDirection ~= 0) and status.overConsumeResource("energy", self.elementConfig.secondaryCosts[3] / self.weaveBonus) then
    attemptActivation()
  end
end

-- Checks if the player can transform.
function attemptActivation()
  if not self.active
      and not tech.parentLounging()
      and not status.statPositive("activeMovementAbilities") then
    local pos = transformPosition()
    if pos then
      mcontroller.setPosition(pos)
      activate()
    end
  elseif self.active and self.joltTimer == 0 then
    local pos = restorePosition()
    if pos then
      mcontroller.setPosition(pos)
    end
    deactivate()
  else
    activate()
  end
end

-- All checks have passed, so Jolt is activated.
function activate()
  if self.joltTimer == 0 then self.transformFadeTimer = self.transformFadeTime - 0.25 end
  self.active = true
  self.cooldownTimerS = 0.2
  self.joltTimer = 0.21
  tech.setParentOffset({0, positionOffset()})
  tech.setParentHidden(true)
  tech.setToolUsageSuppressed(true)
  animator.playSound("jolt")
  status.setPersistentEffects("movementAbility", {
    {stat = "activeMovementAbilities", amount = 1},
    {stat = "activeMovementAbilitiesJolt", amount = 1}
  })
end

-- Deactivates Jolt
function deactivate()
  animator.setAnimationState("jolt", "off")
  self.transformFadeTimer = -self.transformFadeTime
  tech.setParentHidden(false)
  tech.setParentOffset({0, 0})
  tech.setToolUsageSuppressed(false)
  status.clearPersistentEffects("movementAbility")
  --[[if self.weaveElement == "fire" and self.active then
        world.spawnProjectile("electricplasmaexplosion", mcontroller.position(), self.id, {0,0}, false, {power = 20, powerMultiplier = status.stat("powerMultiplier"), speed = 0})
      end]]
  self.active = false
end

function cooldowns(time)
  self.cooldownTimer = time
  self.cooldownTimerS = time
  self.cooldownTimerU = time
end

-- The remaining functions are for the Jolt transformation alone!
function storePosition()
  if self.active then
    storage.restorePosition = restorePosition()

    -- try to restore position. if techs are being switched, this will work and the storage will
    -- be cleared anyway. if the client's disconnecting, this won't work but the storage will remain to
    -- restore the position later in update()
    if storage.restorePosition then
      storage.lastActivePosition = mcontroller.position()
      mcontroller.setPosition(storage.restorePosition)
    end
  end
end

function restoreStoredPosition()
  if storage.restorePosition then
    -- restore position if the player was logged out (in the same planet/universe) with the tech active
    if vec2.mag(vec2.sub(mcontroller.position(), storage.lastActivePosition)) < 1 then
      mcontroller.setPosition(storage.restorePosition)
    end
    storage.lastActivePosition = nil
    storage.restorePosition = nil
  end
end

function positionOffset()
  return minY(self.joltPoly) - minY(self.basePoly)
end


function transformPosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(self.joltPoly, {pos[1], pos[2] - positionOffset() / 2}, 1, self.collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(self.joltPoly, pos, 1, self.collisionSet)
  end
end

function restorePosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(self.basePoly, {pos[1], pos[2] + positionOffset() / 2}, 1, self.collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(self.basePoly, pos, 1, self.collisionSet)
  end
end

function updateTransformFade(dt)
  if self.transformFadeTimer > 0 then
    self.transformFadeTimer = math.max(0, self.transformFadeTimer - dt)
    animator.setGlobalTag("joltDirectives", self.directives .. string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, self.transformFadeTimer / (self.transformFadeTime - 0.275))))
  elseif self.transformFadeTimer < 0 then
    self.transformFadeTimer = math.min(0, self.transformFadeTimer + dt)
    tech.setParentDirectives(self.directives .. string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, -self.transformFadeTimer / (self.transformFadeTime - 0.15))))
  else
    animator.setGlobalTag("joltDirectives", "")
    tech.setParentDirectives(self.directives)
  end
end

function minY(poly)
  local lowest = 0
  for _,point in pairs(poly) do
    if point[2] < lowest then
      lowest = point[2]
    end
  end
  return lowest
end
