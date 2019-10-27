require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = entity.id()
  self.active = false
  self.elementMod = 1
  self.elementList = {"fire", "ice", "electric"}
  self.element = self.elementList[self.elementMod]
  self.newMod = {2,3,1}
  self.statusList = {"ivrpgsear", "ivrpgembrittle", "ivrpgoverload"}
  self.borderList = {"bb552233", "2288cc22", "88882233"}
  self.projectileList = {"dragonfirelarge", "iceshockwave", "balllightning"}
  self.projectileList2 = {"molotovflame", "icetrail", "electrictrail"}
  self.action2List = {worldOnFire, iceBarrier, jolt}
  self.action3List = {meteor, shards, thunder}
  self.charging = false
  self.chargeTimer = 3
  self.cooldownTimer = 0
  self.joltTimer = 0
  self.transformFadeTimer = 0
  self.chargeCooldownTimer = 5
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.joltPoly = config.getParameter("joltCollisionPoly", {})
  self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}
  self.directives = ""
  Bind.create("Up", toggle)
  Bind.create("primaryFire", action1)
  Bind.create("altFire", action1alt)
end

function toggle()
  if self.charging or self.active or not self.shiftHeld then return end
  self.elementMod = self.newMod[self.elementMod]
  self.element = self.elementList[self.elementMod]
  animator.playSound(self.element .. "Activate")
end

function uninit()
  tech.setParentDirectives()
  storePosition()
  deactivate()
  --status.removeEphemeralEffect("ivrpgimmaculateshieldstatus")
end

--[[
A Body Tech: Press [W] to switch between your current attunement. You are immune to an element while attuned to it. Use Left/Right Click, [G] or hold [Shift]+[G] to use an ability based on your Attuned Element and Affinity.
When your Attunement and Weave match, ability cooldown and energy cost are halved.

Primary Fire/Alt Fire: Fire a projectile. - COMPLETE

[G]: Perform an action that can be held. - COMPLETE
Fire - World On Fire | Ice - Ice Barrier | Electric - Jolt

Shift + [G]: Perform an action that requires charging.
Fire - Meteor | Ice - Seeking Shards | Electric - Thunderstorm

]]

function update(args)
  self.directives = "?fade=" .. self.borderList[self.elementMod] .. "=0.5"
  status.setPersistentEffects("ivrpgattune", {
    {stat = self.element .. "StatusImmunity", amount = 1},
    {stat = self.element .. "Resistance", amount = 3},
    {stat = "lavaImmunity", amount = self.element == "fire" and 1 or 0},
    {stat = "invulnerable", amount = self.active and 1 or 0}
  })

  self.weaveMod = status.stat("ivrpgelementalweave")
  self.weaveBonus = self.weaveMod == self.elementMod and 2 or 1

  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.specialHeld = args.moves["special2"]
  self.hDirection = args.moves["left"] and -1 or (args.moves["right"] and 1 or 0)
  self.vDirection = args.moves["up"] and 1 or (args.moves["down"] and -1 or 0)
  if self.specialHeld then
    if (self.shiftHeld or self.charging) and self.chargeCooldownTimer == 0 then
      charge()
    elseif self.cooldownTimer == 0 then
      self.action2List[self.elementMod]()
    end
  else
    self.charging = false
    self.chargeTimer = 3
    self.lastProjectilePosition = nil
    animator.stopAllSounds(self.element .. "Charge")
  end

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

  self.chargeCooldownTimer = math.max(0, self.chargeCooldownTimer - self.dt)

  updateTransformFade(self.dt)
end

--[[Each Ability changes depending on current Weave:
Basic Projectile: Fire - Explosions | Ice - Slows Targets | Electric - Tracks Targets.]]

function action1(skipCheck)
  if (self.cooldownTimer > 0 or self.active) or ((not skipCheck) and world.entityHandItem(self.id, "primary")) then return end
  world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition(),mcontroller.yPosition()-1}, self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, {powerMultiplier = status.stat("powerMultiplier"), speed = 30})
  cooldown(0.5)
end

function action1alt()
  if not world.entityHandItem(self.id, "alt") then
    action1(true)
  end
end

--[[World On Fire: Fire - Sear | Ice - Explosions | Electric - Lingering Damage.
Ice Barrier: Fire - Adds Mist | Ice - Double Duration, Cause Embrittle | Electric - Cause Stun.
Jolt: Fire - Explosions | Ice - Ice Trail | Electric - Increased Distance.]]

function worldOnFire()
  if not status.overConsumeResource("energy", self.dt * 20 / self.weaveBonus) then return end
  local targetIds = enemyQuery(mcontroller.position(), 20, {}, self.id, true)
  for _,id in ipairs(targetIds) do
    world.sendEntityMessage(id, "applyStatusEffect", "burning", 0.25, self.id)
  end
end

function iceBarrier()
  local projectileSource = tech.aimPosition()
  if world.magnitude(projectileSource, mcontroller.position()) > 10 then return end
  if not self.lastProjectilePosition then
    self.lastProjectilePosition = projectileSource
  end
  local minDistance = world.magnitude(mcontroller.position(), projectileSource) - 1
  local dir = vec2.mul(vec2.norm(world.distance(projectileSource, self.lastProjectilePosition)), 1)
  local steps = math.floor(world.magnitude(projectileSource, self.lastProjectilePosition))
  for step = 1, steps do
    local position, aimVector = projectilePositionAndAim(self.lastProjectilePosition, vec2.add(self.lastProjectilePosition, vec2.mul(dir, step)))

    if world.magnitude(position, mcontroller.position()) >= minDistance and not world.lineTileCollision(position, mcontroller.position()) then
      if not status.overConsumeResource("energy", 5 / self.weaveBonus) then break end
      world.spawnProjectile("icebarrier", position, self.id, aimVector, false, {power = 0})
    end
  end
  if steps > 0 then
    self.lastProjectilePosition = vec2.add(self.lastProjectilePosition, vec2.mul(dir, steps))
  end  
end

-- returns the aim vector perpendicular to the distance between the passed in vectors
function projectilePositionAndAim(from, to)
  local direction = vec2.norm(world.distance(to, from))
  local mid = {(from[1] + to[1]) / 2, (from[2] + to[2]) / 2}

  local toOwner = world.distance(mid, world.entityPosition(self.id))

  -- out of the two possible perpendicular vectors, pick the one pointing horizontally away from the player
  local perp1 = {direction[2], -direction[1]}
  local perp2 = {-direction[2], direction[1]}
  direction = vec2.dot(perp1, toOwner) > 0 and perp1 or perp2

  return mid, direction
end


function jolt()
  self.joltDirection = {self.hDirection, self.vDirection}
  if (self.hDirection ~= 0 or self.vDirection ~= 0) and status.overConsumeResource("energy", 10 / self.weaveBonus) then
    attemptActivation()
  end
end

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

function activate()
  if self.joltTimer == 0 then self.transformFadeTimer = self.transformFadeTime - 0.25 end
  self.active = true
  cooldown(0.2)
  self.joltTimer = 0.21
  tech.setParentOffset({0, positionOffset()})
  tech.setParentHidden(true)
  tech.setToolUsageSuppressed(true)
  animator.playSound("jolt")
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
end

function deactivate()
  animator.setAnimationState("jolt", "off")
  self.transformFadeTimer = -self.transformFadeTime
  tech.setParentHidden(false)
  tech.setParentOffset({0, 0})
  tech.setToolUsageSuppressed(false)
  status.clearPersistentEffects("movementAbility")
  self.active = false
end

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

function charge( ... )
  if not self.charging then 
    self.charging = true
    self.chargeTimer = 3
    animator.playSound(self.element .. "Charge")
  end
  self.chargeTimer = math.max(self.chargeTimer - self.dt, 0)
  if self.chargeTimer == 0 then
    self.action3List[self.elementMod]()
    animator.playSound(self.element .. "ChargeActivate")
    self.chargeCooldownTimer = 10
  end
end

--[[Meteor: Fire - Increased Size | Ice - Fragments | Electric - Increased Conjure Speed
Seeking Shards: Fire adds mist, Ice causes Embrittle and increases Shard count, Electric increases Shard speed and adds shard fragments.
Thunderstorm: Fire - Explosions | Ice - Hail | Electric - Increased Size.]]

function meteor( ... )
  world.spawnProjectile("elementresslargemeteor", {mcontroller.xPosition(), mcontroller.yPosition() + 15}, self.id, {mcontroller.facingDirection() / 2, -1}, false, {power = 100, speed = 50})
end

function shards( ... )
  --world.spawnProjectile("icebarrier", position, self.id, aimVector, false, {power = 0})
end

function thunder( ... )
  for i=-5,5 do
    world.spawnProjectile("electricelementcloud", {mcontroller.xPosition() + i, mcontroller.yPosition() + 10}, self.id, {0,0}, false, {power = 10, speed = 0})
  end
end

function cooldown(time)
  self.cooldownTimer = time
end