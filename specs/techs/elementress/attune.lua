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
  self.shiftHeld = false

  -- For increasing Attunement
  self.levelList = status.statusProperty("ivrpgAttunementLevels", {1,1,1})
  self.level = 1
  animator.setAnimationState("gauge", self.element)
  animator.playSound(self.element .. "Activate")
  _, self.damageGivenUpdate = status.inflictedDamageSince()
  --[[
  Basic = 1
  Decent = 2-3
  Great = 4-5
  Chaos = 6-7
  ]]

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
  cooldown(0.2)
end

function uninit()
  tech.setParentDirectives()
  animator.stopAllSounds("flamethrowerStart")
  animator.stopAllSounds("flamethrowerLoop")
  storePosition()
  deactivate()
  status.clearPersistentEffects("ivrpgattune")
  status.setStatusProperty("ivrpgAttunementElement", false)
end

--[[
Basic Fire+: Flame Burst
Shoot flame towards your cursor that lingers when it hits an enemy.

Chaos Fire: Conflagrate
The lingering flame now lingers on contact with walls and creates additional smaller flames that shoot outwards and stick to the ground.

Special Fire: Explosion
Create a magma zone centered around your cursor. Within the magma zone, enemies take constant damage. While the zone exists, bursts of flame build within and are ejected when finished: these bursts explode on contact.


Basic Electric+: Arc Flash
Chain electricity outwards in all directions with a fixed ranged. If any part of the chain contacts with an enemy, that enemy starts a new chain.

Chaos Electric: Pulsate
Bolts chaining from enemies chain to you, granting additional energy, and overcharging Electric Potential. While overcharged, all your Attunement Attacks deal an additional chunk of Electric damage.

Special Electric: Thunder
Call down a quick torrent of massive thunderbolts. Enemies hit by these bolts instantly die if they have less than 50% remaining health.


Basic Ice+: Icicle Rush
Slide forwards, protecting yourself with a heavy icicle which is launched after the slide finishes. If the icicle contacts an enemy during the slide, it impales itself into that enemy, freezing them for one second, and you hop backwards.

Chaos Ice: Shatter
Upon embedding into a wall or enemy, press Primary Fire again to shatter the icicle. Doing so does massive damage in a small space around it, and also scatters ice shards that do minor damage.

Special Ice: Glacier
Summon large spikes of ice underneath three nearby enemies. These freeze enemies they hit, preventing them from moving at all.
]]

function update(args)
  --self.directives = "?fade=" .. self.borderList[self.elementMod] .. "=0.25"
  status.setPersistentEffects("ivrpgattune", {
    {stat = self.element .. "StatusImmunity", amount = 1},
    {stat = self.element .. "Resistance", amount = 3},
    {stat = "lavaImmunity", amount = self.element == "fire" and 1 or 0},
    {stat = "invulnerable", amount = self.active and 1 or 0}
  })

  if self.levelList[self.elementMod] <= 1 then
    self.level = 1
  elseif self.levelList[self.elementMod] <= 3 then
    self.levelName = 2
  elseif self.levelList[self.elementMod] <= 5 then
    self.level = 3
  else
    self.level = 4
  end

  status.setStatusProperty("ivrpgAttunementElement", self.element)

  animator.setGlobalTag(self.element.."Mod", tostring(self.levelList[self.elementMod]))

  self.weaveMod = status.stat("ivrpgelementalweave")
  self.weaveBonus = (self.weaveMod == self.elementMod) and 1.5 or 1

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
    or status.statPositive("activeMovementAbilities") then return end
    if self.shiftHeld and status.overConsumeResource("energy", self.elementConfig.ultimateCosts[self.elementMod] / self.weaveBonus) then
      self.primaryList[self.elementMod]()
      cooldown(3)
    elseif not self.shiftHeld and status.overConsumeResource("energy", self.elementConfig.primaryCosts[self.elementMod][self.level] / self.weaveBonus) then
      self.primaryList[self.elementMod](true)
      cooldown(1)
    else
      return
    end
end

-- Check if Alt Hand is empty when Alt Fire is pressed.
function action1alt()
  local itemConfig = ivrpgBuildItemConfig(self.id, "primary")
  if itemConfig and itemConfig.config and (itemConfig.config.twoHanded or self.twoHandedCategories[itemConfig.config.category]) then return end
  if not world.entityHandItem(self.id, "alt") then action1(true) end
end

-- Primary Fire
function flameBurst(standard)
  if standard then
    world.spawnProjectile(self.elementConfig.primaryProjectiles[1], {mcontroller.xPosition(), mcontroller.yPosition() - 0.5}, self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, {
      power = 4, powerMultiplier = status.stat("powerMultiplier"), speed = 20, timeToLive = 1
    })
  else
    world.spawnProjectile(self.elementConfig.ultimateProjectiles[1], tech.aimPosition(), self.id, {0,0}, false, {
      power = 4, powerMultiplier = status.stat("powerMultiplier"), speed = 0, timeToLive = 5
    })
  end
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
  if self.fireTimer <= 0 and status.overConsumeResource("energy", self.dt * 30 / self.weaveBonus) then
    world.spawnProjectile(self.elementConfig.secondaryProjectiles[1], vec2.add(mcontroller.position(), {mcontroller.facingDirection() / 2, -0.25}), self.id, aimDirection(0.05), false, {
      power = 0.5, powerMultiplier = status.stat("powerMultiplier")
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
      local projectileId = world.spawnProjectile(self.elementConfig.secondaryProjectiles[2], vec2.add(position, {facingDirection * 3, i}), self.id, {facingDirection, 0}, true, {power = 0, timeToLive = math.huge})
      if projectileId then table.insert(self.barrierProjectiles, projectileId) end
      projectileId = world.spawnProjectile(self.elementConfig.secondaryProjectiles[2], vec2.add(position, {-facingDirection * 3, i}), self.id, {-facingDirection, 0}, true, {power = 0, timeToLive = math.huge})
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