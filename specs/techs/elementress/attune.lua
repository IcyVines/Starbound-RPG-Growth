require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
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
  self.projectileList = {"elementressfireball", "elementressicespike", "elementresselectricspin"}
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
  self.projectiles = {}
  self.barrierProjectiles = {}
  self.altBarrierProjectiles = {}
  self.barrierFacing = 1
  self.powerUp = false
  self.iceTimer = 0
  self.mistTimer = 0
  self.twoHandedCategories = config.getParameter("twoHandedCategories", {})
  Bind.create("specialThree", toggle)
  Bind.create("primaryFire", action1)
  Bind.create("altFire", action1alt)
end

function toggle()
  if self.charging or self.active then return end
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
When your Attunement and Weave match, energy cost is halved.

Primary Fire/Alt Fire: Fire a projectile. - COMPLETE

[G]: Perform an action that can be held. - COMPLETE
Fire - World On Fire | Ice - Ice Barrier | Electric - Jolt

Shift + [G]: Perform an action that requires charging.
Fire - Meteor | Ice - Seeking Shards | Electric - Thunderstorm

]]

function update(args)
  self.directives = "?fade=" .. self.borderList[self.elementMod] .. "=0.25"
  status.setPersistentEffects("ivrpgattune", {
    {stat = self.element .. "StatusImmunity", amount = 1},
    {stat = self.element .. "Resistance", amount = 3},
    {stat = "lavaImmunity", amount = self.element == "fire" and 1 or 0},
    {stat = "invulnerable", amount = self.active and 1 or 0}
  })

  self.weaveMod = status.stat("ivrpgelementalweave")
  self.weaveBonus = self.weaveMod == self.elementMod and 2 or 1
  self.weaveElement = self.elementList[self.weaveMod]

  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.specialHeld = args.moves["special2"]
  self.hDirection = args.moves["left"] and -1 or (args.moves["right"] and 1 or 0)
  self.vDirection = args.moves["up"] and 1 or (args.moves["down"] and -1 or 0)
  if self.specialHeld then
    if (self.shiftHeld or self.charging) and self.chargeCooldownTimer == 0 and not status.resourceLocked("energy") and status.overConsumeResource("energy", self.dt * 10 / self.weaveBonus) then
      charge()
    elseif self.cooldownTimer == 0 and not self.shiftHeld then
      self.action2List[self.elementMod]()
    end
  else
    self.charging = false
    self.chargeTimer = 3
    self.lastProjectilePosition = nil
    killIceBarrier()
    animator.stopAllSounds(self.element .. "Charge")
  end

  if self.element ~= "ice" or self.shiftHeld then
    killIceBarrier()
  end

  if self.weaveElement == "ice" then
    if #self.barrierProjectiles > 0 then
      if #self.altBarrierProjectiles == 0 then
        for i=-2,2 do
          local projectileId = world.spawnProjectile("elementressicebarrier", vec2.add(mcontroller.position(), {self.barrierFacing * -1 * 3, i}), self.id, {self.barrierFacing * -1, 0}, true, {power = 0, timeToLive = math.huge})
          if projectileId then table.insert(self.altBarrierProjectiles, projectileId) end
        end
      end
    end

    if self.active and self.iceTimer == 0 then
      self.iceTimer = 0.03
      world.spawnProjectile("icetrail", mcontroller.position(), self.id, {0,0}, false, {power = 1, speed = 0})
    end

  else
    killIceBarrier(true)
  end

  if self.weaveElement == "fire" then
    if self.mistTimer == 0 then
      for _,id in ipairs(self.barrierProjectiles) do
        world.spawnProjectile("ivrpgsearingmist", world.entityPosition(id), self.id, {0,0}, false, {})
      end
      self.mistTimer = 0.5
    end
  else

  end

  local joltBonus = 0
  local powerUp = false
  if self.weaveElement == "electric" then
    powerUp = true
    joltBonus = 100
  else
    powerUp = false  
  end

  if #self.barrierProjectiles > 0 and self.powerUp ~= powerUp then
    self.powerUp = powerUp
    for _,id in ipairs(self.barrierProjectiles) do
      world.sendEntityMessage(id, "setPower", powerUp and 1 or 0)
    end
  end

  if self.active then
    mcontroller.controlParameters({
      gravityEnabled = false,
      runningSuppressed = true,
      collisionPoly = self.joltPoly
    })
    status.setResourcePercentage("energyRegenBlock", 1.0)
    mcontroller.controlApproachVelocity(vec2.mul(self.joltDirection, 100 + joltBonus), 1000 + joltBonus * 5)
    animator.setAnimationState("jolt", "on")
  else
    animator.setAnimationState("jolt", "off")
  end

  if #self.projectiles > 0 then
    local newProjectiles = {}
    for k,id in ipairs(self.projectiles) do
      if world.entityExists(id) then
        table.insert(newProjectiles, id)
      end
    end
    self.projectiles = copy(newProjectiles)
  end

  self.iceTimer = math.max(0, self.iceTimer - self.dt)
  self.mistTimer = math.max(0, self.mistTimer - self.dt)
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
Basic Projectile: Fire - Increased Damage | Ice - Lasts Longer | Electric - Decreased Cooldown.]]

function action1(skipCheck)
  if (self.cooldownTimer > 0 or self.active) or ((not skipCheck) and world.entityHandItem(self.id, "primary")) then return end
  if not status.overConsumeResource("energy", 25 / self.weaveBonus) then return end
  local bonusTime = self.weaveElement == "ice" and 0.2 or 0
  local bonusDamage = self.weaveElement == "fire" and 1.5 or 1
  local bonusCooldown = self.weaveElement == "electric" and 0.5 or 0
  if self.element == "ice" then
    --world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition(),mcontroller.yPosition()-1}, self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, {power = 5, powerMultiplier = status.stat("powerMultiplier"), speed = 0, timeToLive = 0.5})
    world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition() + mcontroller.facingDirection() * 4, mcontroller.yPosition() - 0.5}, self.id, {mcontroller.facingDirection(), 0}, true, {power = 4 * bonusDamage, powerMultiplier = status.stat("powerMultiplier"), speed = 0, timeToLive = 0.25 + bonusTime, animationCycle = 0.25 + bonusTime})
    world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition() + mcontroller.facingDirection() * 3, mcontroller.yPosition() - 2.5}, self.id, {mcontroller.facingDirection(), -1}, true, {power = 4 * bonusDamage, powerMultiplier = status.stat("powerMultiplier"), speed = 0, timeToLive = 0.25 + bonusTime, animationCycle = 0.25 + bonusTime})
    world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition() + mcontroller.facingDirection() * 3, mcontroller.yPosition() + 1.5}, self.id, {mcontroller.facingDirection(), 1}, true, {power = 4 * bonusDamage, powerMultiplier = status.stat("powerMultiplier"), speed = 0, timeToLive = 0.25 + bonusTime, animationCycle = 0.25 + bonusTime})
  elseif self.element == "fire" then
    world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition(), mcontroller.yPosition() - 0.5}, self.id, {mcontroller.facingDirection(), 0}, false, {power = 4 * bonusDamage, powerMultiplier = status.stat("powerMultiplier"), speed = 20, timeToLive = 0.5 + bonusTime})
  elseif self.element == "electric" then
    world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition(), mcontroller.yPosition() - 0.5}, self.id, {0, 0}, true, {power = 2 * bonusDamage, powerMultiplier = status.stat("powerMultiplier"), speed = 0, timeToLive = 0.8 + bonusTime})
  end
  cooldown(1.5 - bonusCooldown)
end

function action1alt()
  local itemConfig = ivrpgBuildItemConfig(self.id, "primary")
  if itemConfig and itemConfig.config and (itemConfig.config.twoHanded or self.twoHandedCategories[itemConfig.config.category]) then return end
  if not world.entityHandItem(self.id, "alt") then
    action1(true)
  end
end

--[[
World On Fire: Fire - Range Up * | Ice - Searing Mist * | Electric - Lingering Damage *
Ice Barrier: Fire - Searing Mist * | Ice - Both Directions * | Electric - Contact Damage *
Jolt: Fire - Explode Upon Deactivation * | Ice - Ice Trail * | Electric - Increased Distance *
]]

function worldOnFire()
  if not status.overConsumeResource("energy", self.dt * 20 / self.weaveBonus) then return end

  if self.weaveElement == "ice" and self.mistTimer == 0 then
    world.spawnProjectile("ivrpgsearingmist", vec2.add(mcontroller.position(), {math.random() - 0.5, math.random()*2 - 1}), self.id, {0,0}, false, {})
    self.mistTimer = 0.1
  end

  local targetIds = enemyQuery(mcontroller.position(), 15 + (self.weaveElement == "fire" and 10 or 0), {}, self.id, true)
  for _,id in ipairs(targetIds) do
    world.sendEntityMessage(id, "applyStatusEffect", "burning", 0.25 + (self.weaveElement == "electric" and 5 or 0), self.id)
  end
end

function iceBarrier()
  local facingDirection = mcontroller.facingDirection()
  local position = mcontroller.position()
  if (not status.overConsumeResource("energy", self.dt * 10 / self.weaveBonus)) then
    killIceBarrier()
    return
  end

  if #self.barrierProjectiles == 0 then 
    for i=-2,2 do
      local projectileId = world.spawnProjectile("elementressicebarrier", vec2.add(position, {facingDirection * 3, i}), self.id, {facingDirection, 0}, true, {power = 0, timeToLive = math.huge})
      if projectileId then table.insert(self.barrierProjectiles, projectileId) end
    end
    self.barrierFacing = facingDirection
  end
end

function killIceBarrier(altOnly)
  for _,id in ipairs(self.altBarrierProjectiles) do
    world.sendEntityMessage(id, "kill")
  end
  self.altBarrierProjectiles = {}

  if altOnly then return end

  self.powerUp = false
  for _,id in ipairs(self.barrierProjectiles) do
    world.sendEntityMessage(id, "kill")
  end
  self.barrierProjectiles = {}
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
  if self.weaveElement == "fire" and self.active then
    world.spawnProjectile("electricplasmaexplosion", mcontroller.position(), self.id, {0,0}, false, {power = 20, powerMultiplier = status.stat("powerMultiplier"), speed = 0})
  end
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
    animator.playSound(self.element .. "ChargeActivate")
    self.chargeCooldownTimer = 10
    self.action3List[self.elementMod]()
    self.charging = false
    self.chargeTimer = 3
  end
end

--[[
Meteor: Fire - More Flames * | Ice - Fragments * | Electric - Decreased Cooldown *
Seeking Shards: Fire - Searing Mist * | Ice - +2 Shards * | Electric - Improved Tracking Range, Faster *
Thunderstorm: Fire - Explosions | Ice - Hail | Electric - Increased Size *
]]

function meteor( ... )
  local projectileName = "elementresslargemeteor"
  local range = 1
  if self.weaveElement == "fire" then
    projectileName = projectileName .. "fire"
  elseif self.weaveElement == "ice" then
    projectileName = projectileName .. "ice"
    range = 2
  end
  world.spawnProjectile(projectileName, {mcontroller.xPosition(), mcontroller.yPosition() + 15}, self.id, {mcontroller.facingDirection() / 2, -1}, false, {power = 50, powerMultiplier = status.stat("powerMultiplier") / 2, speed = 30})
  for i=-range,range do
    world.spawnProjectile("elementresssmallmeteor", {mcontroller.xPosition() + i * 5, mcontroller.yPosition() + 10}, self.id, {mcontroller.facingDirection() * math.random(), -1}, false, {power = 5, powerMultiplier = status.stat("powerMultiplier"), speed = 40})
  end
  if self.weaveElement == "electric" then self.chargeCooldownTimer = 7.5 end
end

function shards( ... )
  local bonusRange = self.weaveElement == "ice" and 1 or 0
  local range = 1 + bonusRange
  local projectileName = "ivrpgelementressshard"
  if self.weaveElement == "fire" then
    projectileName = projectileName .. "fire"
  elseif self.weaveElement == "electric" then
    projectileName = projectileName .. "electric"
  end
  for i=-range,range do
    local projectileId = world.spawnProjectile(projectileName, vec2.add(mcontroller.position(), {i, 0}), self.id, {0,0}, false, {power = 5, randPos = i, powerMultiplier = status.stat("powerMultiplier")})
    if projectileId then
      table.insert(self.projectiles, projectileId)
    end
  end
end

function thunder( ... )
  local bonusRange = self.weaveElement == "electric" and 2 or 0
  local range = 3 + bonusRange
  local projectileName = "elementresselectricelementcloud"
  if self.weaveElement == "fire" then
    projectileName = projectileName .. "fire"
  elseif self.weaveElement == "ice" then
    projectileName = projectileName .. "ice"
  end
  for i=-range,range do
    world.spawnProjectile(projectileName, {mcontroller.xPosition() + i*3, mcontroller.yPosition() + 12 - math.abs(i/3)}, self.id, {0,0}, false, {power = 5, powerMultiplier = status.stat("powerMultiplier"), speed = 0})
  end
end

function cooldown(time)
  self.cooldownTimer = time
end