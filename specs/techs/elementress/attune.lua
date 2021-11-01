require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  local elementConfig = config.getParameter("elementConfig", {})

  -- General variables
  self.id = entity.id()
  self.elementMod = status.statusProperty("ivrpgAttunement", 1)
  self.elementList = elementConfig.elements
  self.element = self.elementList[self.elementMod]
  self.statusList = elementConfig.statuses
  self.borderList = elementConfig.fades
  self.projectileList = elementConfig.primaryProjectiles
  self.projectileList2 = elementConfig.secondaryProjectiles
  self.primaryList = {flameBurst, icicleRush, arcFlash}
  self.action2List = {updateFireStream, updateIceBarrier, activateJolt}
  self.newMod = {2,3,1}
  self.directives = ""
  self.twoHandedCategories = config.getParameter("twoHandedCategories", {})
  self.cooldownTimer = 0

  -- For increasing Attunement
  self.levelList = status.statusProperty("ivrpgAttunementLevels", {1,1,1})
  animator.setAnimationState("gauge", self.element)
  animator.playSound(self.element .. "Activate")
  _, self.damageGivenUpdate = status.inflictedDamageSince()
  
  -- Jolt specific variables
  self.joltTimer = 0
  self.transformFadeTimer = 0
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.joltPoly = config.getParameter("joltCollisionPoly", {})
  self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}
  self.active = false

  -- Ice Barrier specific variables
  self.barrierProjectiles = {}
  self.barrierFacing = 1

  -- Flamethrower specific variables
  self.fireTime = 0.065
  self.fireTimer = 0

  Bind.create("specialTwo", toggle)
  Bind.create("primaryFire", action1)
  Bind.create("altFire", action1alt)
end

function toggle()
  if self.active or not self.shiftHeld then return end
  self.elementMod = self.newMod[self.elementMod]
  self.element = self.elementList[self.elementMod]
  animator.setAnimationState("gauge", self.element)
  status.setStatusProperty("ivrpgAttunement", self.elementMod)
  status.setStatusProperty("ivrpgAttunementLevels", self.levelList)
  animator.playSound(self.element .. "Activate")
end

function uninit()
  tech.setParentDirectives()
  animator.stopAllSounds("flamethrowerStart")
  animator.stopAllSounds("flamethrowerLoop")
  storePosition()
  deactivate()
  status.clearPersistentEffects("ivrpgattune")
end

function update(args)
  --self.directives = "?fade=" .. self.borderList[self.elementMod] .. "=0.25"
  status.setPersistentEffects("ivrpgattune", {
    {stat = self.element .. "StatusImmunity", amount = 1},
    {stat = self.element .. "Resistance", amount = 3},
    {stat = "lavaImmunity", amount = self.element == "fire" and 1 or 0},
    {stat = "invulnerable", amount = self.active and 1 or 0}
  })

  animator.setGlobalTag(self.element.."Mod", tostring(self.levelList[self.elementMod]))

  self.weaveMod = status.stat("ivrpgelementalweave")
  self.weaveBonus = self.weaveMod == self.elementMod and 2 or 1
  self.weaveElement = self.elementList[self.weaveMod]

  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.specialHeld = args.moves["special2"]
  self.hDirection = args.moves["left"] and -1 or (args.moves["right"] and 1 or 0)
  self.vDirection = args.moves["up"] and 1 or (args.moves["down"] and -1 or 0)

  if self.specialHeld and not (status.statPositive("activeMovementAbilities") and not status.statPositive("activeMovementAbilitiesJolt")) and self.cooldownTimer == 0 and not self.shiftHeld then
    self.action2List[self.elementMod]()
  else
    if self.fireActive then
      animator.playSound("flamethrowerEnd")
    end
    self.fireActive = false
    killIceBarrier()
  end
  
  if self.element ~= "ice" then
    killIceBarrier()
  end

  if self.element ~= "fire" or not self.fireActive then
    animator.stopAllSounds("flamethrowerStart")
    animator.stopAllSounds("flamethrowerLoop")
    if self.fireActive then
      animator.playSound("flamethrowerEnd")
      self.fireActive = false
    end
  end

  self.fireTimer = self.fireTimer - self.dt

  updateJolt()
  updateTransformFade(self.dt)

  updateDamageGiven()
end

-- Required to update Attunement Level
function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 and notification.damageSourceKind == ("ivrpg_elementress" .. self.element) then
        self.levelList[self.elementMod] = math.min(self.levelList[self.elementMod] + 1, 7)
      end
    end
  end
end

function aimDirection(inaccuracy)
  return vec2.rotate(world.distance(tech.aimPosition(), mcontroller.position()), sb.nrand(inaccuracy or 0, 0))
end
  
-- Check if the Primary Projectile can be fired.
function action1(skipCheck)
  if (self.cooldownTimer > 0 or self.active) or ((not skipCheck)
    and world.entityHandItem(self.id, "primary"))
    or status.statPositive("activeMovementAbilities")
    or not status.overConsumeResource("energy", 25 / self.weaveBonus) then return end
  self.primaryList[self.elementMod]()
  cooldown(1)
end

-- Check if Alt Hand is empty when Alt Fire is pressed.
function action1alt()
  local itemConfig = ivrpgBuildItemConfig(self.id, "primary")
  if itemConfig and itemConfig.config and (itemConfig.config.twoHanded or self.twoHandedCategories[itemConfig.config.category]) then return end
  if not world.entityHandItem(self.id, "alt") then action1(true) end
end

-- Primary Fire
function flameBurst()
  world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition(), mcontroller.yPosition() - 0.5}, self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, {
    power = 4, powerMultiplier = status.stat("powerMultiplier"), speed = 20, timeToLive = 1
  })
end

-- Primary Ice
function icicleRush()
    -- To do
end

-- Primary Electric
function arcFlash()
    -- To do
end

-- Flame Thrower
function updateFireStream()
  if not self.fireActive then
    animator.playSound("flamethrowerStart")
    animator.playSound("flamethrowerLoop", -1)
  end
  self.fireActive = true
  if self.fireTimer <= 0 and status.overConsumeResource("energy", self.dt * 10 / self.weaveBonus) then
    world.spawnProjectile("flamethrower", vec2.add(mcontroller.position(), {mcontroller.facingDirection() / 2, -0.25}), self.id, aimDirection(0.05), false, {
      power = 0.1, powerMultiplier = status.stat("powerMultiplier")
    })
    self.fireTimer = self.fireTime
  end
end

-- Spawn Ice Barrier
function updateIceBarrier()
  local facingDirection = mcontroller.facingDirection()
  local position = mcontroller.position()  
  if self.element == "ice" and #self.barrierProjectiles == 0 then 
    for i=-2,2 do
      local projectileId = world.spawnProjectile("elementressicebarrier", vec2.add(position, {facingDirection * 3, i}), self.id, {facingDirection, 0}, true, {power = 0, timeToLive = math.huge})
      if projectileId then table.insert(self.barrierProjectiles, projectileId) end
      projectileId = world.spawnProjectile("elementressicebarrier", vec2.add(position, {-facingDirection * 3, i}), self.id, {-facingDirection, 0}, true, {power = 0, timeToLive = math.huge})
      if projectileId then table.insert(self.barrierProjectiles, projectileId) end
    end
  elseif self.element ~= "ice" or not status.overConsumeResource("energy", self.dt * 10 / self.weaveBonus) then
    killIceBarrier()
  end

end

-- Self explanatory
function killIceBarrier()
  for _,id in ipairs(self.barrierProjectiles) do
    world.sendEntityMessage(id, "kill")
  end
  self.barrierProjectiles = {}
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

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.joltTimer = math.max(0, self.joltTimer - self.dt)
  
  if self.cooldownTimer == 0 then
    if self.active then
      mcontroller.setVelocity({0,0})
      if self.joltTimer == 0 then attemptActivation() end
    end
  end
end

-- Calls attemptActivation if a movement key is held and there is energy left to Jolt.
function activateJolt()
  self.joltDirection = {self.hDirection, self.vDirection}
  if (self.hDirection ~= 0 or self.vDirection ~= 0) and status.overConsumeResource("energy", 10 / self.weaveBonus) then
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
  cooldown(0.2)
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

function cooldown(time)
  self.cooldownTimer = time
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