require "/scripts/keybinds.lua"
require "/scripts/util.lua"
require "/specs/techs/changeling/shapeshiftHelper.lua"

function init()
  self.id = entity.id()
  initCommonParameters()
  status.setStatusProperty("ivrpgshapeshift", true)
  Bind.create("f", shapeshift)
  Bind.create("g", action1, true)
  Bind.create("h", action2, true)
  Bind.create("primaryFire", primaryFire)
  Bind.create("altFire", altFire)
end

function shapeshift()
  if self.frameCooldownTimer > 0 or self.altFrameCooldownTimer > 0 then return end
  self.oldCreature = self.creature
  if self.shiftHeld and self.downHeld and self.giantAvailable then
    self.giantTransform = true
    self.creature = false
    attemptActivation(false)
    return
  elseif self.downHeld then
    self.creature = "orbide"
  elseif self.shiftHeld then
    self.creature = "poptop"
  else
    self.creature = "wisper"
  end
  attemptActivation(self.oldCreature == self.creature)
end

function alreadyActive()
  if self.chargeFire or self.frameCooldownTimer > 0 or self.altFrameCooldownTimer > 0 or self.invulnerable or self.crouchTimer > 0 or self.getupTimer > 0 or self.roaringTimer > 0 then
    self.whistling = false
    return true
  end
end

function suppressMovement(allMovement)
  allMovement = allMovement == nil or allMovement
  mcontroller.controlModifiers({
    runningSuppressed = true,
    jumpingSuppressed = true,
    movementSuppressed = allMovement
  })
end

function action1()
  if alreadyActive() then return end
  if self.creature == "wisper" and status.overConsumeResource("energy", self.dt * 20) then
    toggleEthereal()
  elseif self.creature == "poptop" and mcontroller.onGround() and status.overConsumeResource("energy", self.dt * 10) then
    toggleWhistle()
  elseif self.creature == "adultpoptop" and self.roaringCooldownTimer == 0 and mcontroller.onGround() and status.overConsumeResource("energy", 2 * self.energyCost) then
    activateRoar()
    self.roaringTimer = 0.53
    self.roaringCooldownTimer = 2
  elseif self.creature == "orbide" and mcontroller.onGround() and status.resource("energy") > 12 then
    self.crouchTimer = 1.2
  end
end

-- Action1 Functions

function toggleEthereal()
  mcontroller.controlParameters({
    collisionEnabled = false
  })
  if not self.soundActive then
    animator.playSound("ghostly", -1)
    self.soundActive = true
  end
end

function toggleWhistle()
  suppressMovement(false)
  self.whistling = true
  self.whistlingTimer = math.min(self.whistlingTimer + self.dt, 18)
  mcontroller.controlMove(self.hDirection ~= 0 and self.hDirection or mcontroller.facingDirection())
  status.addEphemeralEffect("ivrpgpoptoppower", self.dt * (self.whistlingTimer) * (100), self.id)
end

function activateRoar()
  local targetIds = world.entityQuery(mcontroller.position(), 20, {
    includedTypes = {"creature"}
  })
  for i,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "enemy" and (world.entityAggressive(id) or world.entityCanDamage(self.id, id)) then
      world.sendEntityMessage(id, "addEphemeralEffect", "soldierstun", 0.5, self.id)
      world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgdisoriented", 2, self.id)
    elseif world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
      world.sendEntityMessage(id, "addEphemeralEffect", "rage", 5, self.id)
    end
  end
end

--

function action2()
  if alreadyActive() then return end
  if self.creature == "wisper" and vec2.mag(mcontroller.velocity()) > 0.1 and status.overConsumeResource("energy", self.dt * 10) then
    self.speedModifier = 2
  elseif self.creature == "poptop" and self.bloodlust > 20 then
    self.oldCreature = self.creature
    self.creature = "adultpoptop"
    attemptActivation(false)
  elseif self.creature == "orbide" and math.abs(mcontroller.xVelocity()) > 0.1 and status.overConsumeResource("energy", self.dt * 10) then
    self.speedModifier = 3
    self.grit = 1
    mcontroller.controlModifiers({
      speedModifier = self.speedModifier
    })
  end
end

function primaryFire()
  if alreadyActive() or self.fireCooldownTimer > 0 then return end
  if self.creature == "wisper" then
    wisperFire()
  elseif self.creature == "poptop" then
    poptopFire()
  elseif self.creature == "adultpoptop" then
    adultpoptopFire()
  elseif self.creature == "orbide" then
    orbideFire()
  end
end

-- Primary Fire Functions

function wisperFire()
  if status.overConsumeResource("energy", self.energyCost) then
    animator.setAnimationState("wisperState", "firewindup")
    self.chargeFire = true
    self.fireTimer = 0.8
  end
end

function orbideFire()
  if status.overConsumeResource("energy", self.energyCost) then
    animator.setAnimationState("orbideState", "chargewindup")
    self.chargeFire = true
    self.fireTimer = 1
  end
end

function poptopFire()
  if status.overConsumeResource("energy", self.energyCost / 2) then
    animator.setAnimationState("poptopState", "chargewindup")
    self.chargeFire = true
    self.fireTimer = 0.4
  end
end

function adultpoptopFire()
  if status.overConsumeResource("energy", self.energyCost / 2) then
    animator.setAnimationState("adultpoptopState", "chargewindup")
    self.chargeFire = true
    self.fireTimer = 0.5
  end
end

-- 

function altFire()
  if alreadyActive() or self.fireCooldownTimer > 0 then return end
  if self.creature == "wisper" then
    wisperAltFire()
  elseif self.creature == "poptop" or self.creature == "adultpoptop" then
    poptopAltFire()
  elseif self.creature == "orbide" then
    orbideAltFire()
  end
end

-- Alt Fire Functions

function wisperAltFire()
  if status.overConsumeResource("energy", self.energyCost / 2) then
    animator.setAnimationState("wisperState", "firewindup")
    self.chargeFire = true
    self.wisperExplosion = true
    self.fireTimer = 0.8
  end
end

function poptopAltFire()
  if mcontroller.onGround() and status.overConsumeResource("energy", self.energyCost) then
    animator.setAnimationState(self.creature .. "State", "devour")
    self.altFrameCooldownTimer = 0.7
    self.fireCooldownTimer = 1.4
  end
end

function devour()
  if self.devouring then
    local health = world.entityHealth(self.devouring)
    if health then
      damage = status.resource("health") > health[1] and health[1] + 1 or health[2] / 4
      world.sendEntityMessage(self.devouring, "applySelfDamageRequest", "IgnoresDef", "alwaysbleed", damage, self.id)
      world.sendEntityMessage(self.devouring, "setVelocity", {mcontroller.facingDirection()*20, 5})
      if damage < health[1] then world.sendEntityMessage(self.devouring, "ivrpgDevourState", self.id) end
      status.modifyResource("health", damage / 2)
      self.bloodlust = self.bloodlust + 5
      self.giantCounter = self.giantCounter + 1
    end
    self.devouring = false
    return
  end
  local size = self.creature == "adultpoptop" and 4 or 2
  size = self.melty and size / 2 or size
  for i,id in ipairs(world.entityQuery(mcontroller.position(), size)) do
    if world.entityAggressive(id) and world.entityDamageTeam(id).type ~= "friendly" then
      world.sendEntityMessage(id, "ivrpgDevourState", self.id, mcontroller.position(), mcontroller.facingDirection())
      self.devouring = id
      return
    end
  end
end

function orbideAltFire()
  if status.overConsumeResource("energy", self.energyCost / 2) then
    animator.setAnimationState("orbideState", "attack")
    world.spawnProjectile("ivrpgorbideattack" .. (self.melty and "melty" or ""), mcontroller.position(), self.id, {mcontroller.facingDirection(),0}, true, {
      power = 15 * status.stat("powerMultiplier")
    })
    self.altFrameCooldownTimer = 0.2
    self.fireCooldownTimer = 0.5
  end
end

--

function uninit()
  tech.setParentDirectives()
  self.oldPoly = false
  storePosition()
  deactivate()
  status.clearPersistentEffects("ivrpgshapeshift")
  status.setStatusProperty("ivrpgshapeshift", false)
end

function update(args)
  meltyBlood()
  restoreStoredPosition()
  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.downHeld = args.moves["down"]
  self.hDirection = (args.moves["left"] == args.moves["right"]) and 0 or (args.moves["right"] and 1 or -1)
  self.vDirection = (args.moves["up"] == self.downHeld) and 0 or (self.downHeld and -1 or 1)

  self.directives = ""
  if self.active then
    if self.melty then
      self.directives = "?scalenearest=0.5"
    else
       self.basePoly = mcontroller.baseParameters().standingPoly
    end
    self.directives = self.directives .. "?hueshift=" .. self.hueShift
    if string.find(self.creature or "", "poptop") then self.directives = self.directives .. "?fade=FF0000=" .. math.min(self.bloodlust / 50, 0.5) end
    if self.creature == "adultpoptop" and self.devouring then self.directives = self.directives .. "?multiply=FFFFFFAA" end
  else
    self.basePoly = mcontroller.collisionPoly()
  end
  if self.flashTimer > 0 then self.directives = self.directives .. "?fade=FFEEFF=" .. self.flashTimer end
  if self.giant then self.directives = "?scalenearest=3" end

  if not args.moves["special1"] then
    self.forceTimer = nil
  end

  if not args.moves["special2"] or (self.creature == "orbide" and (self.crouchTimer > 0 or self.invulnerable) and not status.overConsumeResource("energy", self.dt * 10)) or status.resourceLocked("energy") then
    animator.stopAllSounds("ghostly")
    self.whistling = false
    self.soundActive = false
    self.crouchTimer = 0
    if self.invulnerable then
      self.getupTimer = 1.2
    end
    self.invulnerable = false
  elseif self.creature == "wisper" then
    self.directives = self.directives .. "?multiply=AA66AACC"
  end

  if not args.moves["special3"] or status.resourceLocked("energy") then
    self.speedModifier = 1
    self.grit = 0
  end

  if self.chargeFire or self.frameCooldownTimer > 0 then
    animator.setAnimationRate(1)
  end

  if not (self.creature == "orbide") then
    animator.setAnimationRate(1)
    self.grit = 0
  end

  if not (self.creature == "wisper") then
    self.wisperExplosion = false
  end

  if self.active then
    local collisionPoly = config.getParameter(self.creature .. (self.melty and "MeltyCollisionPoly" or  "CollisionPoly"))
    self.transformedMovementParameters.collisionPoly = collisionPoly
    mcontroller.controlParameters(self.transformedMovementParameters)
    if self.creature == "adultpoptop" and not self.devouring and self.bloodlust == 0 then
      self.oldCreature = self.creature
      self.creature = "poptop"
      attemptActivation(false)
    end
    updateFrame(args.dt)
    checkForceDeactivate(args.dt)
    calculateActives(args.dt)
  elseif self.giant then
    mcontroller.controlParameters(config.getParameter("giantMovementParameters"))
    if mcontroller.crouching() then tech.setParentState("Stand") else tech.setParentState() end
  end

  calculatePassives()

  if self.giantCounter >= 50 and not self.giantAvailable then
    self.giantAvailable = true
    self.flashTimer = 1
  end

  if self.chargeFire or self.frameCooldownTimer > 0 or self.altFrameCooldownTimer > 0 then
    if self.creature == "wisper" then
      mcontroller.controlFace(world.distance(tech.aimPosition(), mcontroller.position())[1] > 0 and 1 or -1)
    elseif self.creature == "poptop" or self.creature == "adultpoptop" then
      if self.frameCooldownTimer > 0 or self.altFrameCooldownTimer > 0 then
        suppressMovement()
        if self.altFrameCooldownTimer > 0.2 and not self.devouring then devour() end
        if self.altFrameCooldownTimer <= 0.2 and self.devouring then devour() end
      else
        if self.hDirection ~= 0 then mcontroller.controlFace(self.hDirection) end
        self.devouring = false
      end
    elseif self.creature == "orbide" then
      if self.frameCooldownTimer > 0 or self.altFrameCooldownTimer > 0 then
        suppressMovement()
      else
        if self.hDirection ~= 0 then mcontroller.controlFace(self.hDirection) end
      end
    end
  end

  updateTransformFade(args.dt)
  self.fireCooldownTimer = math.max(self.fireCooldownTimer - args.dt, 0)
  self.frameCooldownTimer = math.max(self.frameCooldownTimer - args.dt, 0)
  self.altFrameCooldownTimer = math.max(self.altFrameCooldownTimer - args.dt, 0)
  self.hurtTimer = math.max(self.hurtTimer - args.dt, 0)
  if not self.whistling then
    self.whistlingTimer = 0
  end
  self.roaringTimer = math.max(self.roaringTimer - args.dt, 0)
  self.bloodlust = math.max(math.min(self.bloodlust, 25) - args.dt, 0)
  self.roaringCooldownTimer = math.max(self.roaringCooldownTimer - args.dt, 0)
  self.lastPosition = mcontroller.position()
  self.flashTimer = math.max(self.flashTimer - args.dt, 0)
  if self.giantTimer > 0 then
    self.giantTimer = math.max(self.giantTimer - args.dt, 0)
    if self.giantTimer == 0 then
      deactivate()
    end
  end
end

function calculateActives(dt)
  if self.chargeFire then
    if self.fireTimer > 0 then
      self.fireTimer = math.max(self.fireTimer - dt, 0)
      if self.creature == "orbide" or self.creature == "poptop" or self.creature == "adultpoptop" then
        suppressMovement()
      end
    else
      if self.creature == "wisper" then
        animator.setAnimationState(self.creature .. "State", "fire")
        self.frameCooldownTimer = 0.3
        if self.wisperExplosion then
          self.wisperExplosion = false
          local healthPercent = status.resource("health") / status.stat("maxHealth")
          healthPercent = math.min(healthPercent - 0.01, 0.1)
          status.modifyResourcePercentage("health", -healthPercent)
          world.spawnProjectile("iceplasmaexplosionstatus", mcontroller.position(), self.id, {0,0}, true, {
            power = 500 * status.stat("powerMultiplier") * healthPercent
          })
        else
          world.spawnProjectile("iceshot", mcontroller.position(), self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, {speed = 40, power = 20 * status.stat("powerMultiplier")})
        end
      elseif self.creature == "poptop" or self.creature == "adultpoptop" then
        animator.setAnimationState(self.creature .. "State", "charge")
        world.spawnProjectile("ivrpg" .. self.creature .. "charge" .. (self.melty and "melty" or ""), {mcontroller.xPosition(), mcontroller.yPosition() + ((self.creature == "poptop" and self.melty) and 0.25 or 0)}, self.id, {mcontroller.facingDirection(),0}, true, {
          power = 30 * status.stat("powerMultiplier")
        })
        self.frameCooldownTimer = 0.4
      elseif self.creature == "orbide" then
        animator.setAnimationState(self.creature .. "State", "charge")
        world.spawnProjectile("ivrpgorbidecharge" .. (self.melty and "melty" or ""), mcontroller.position(), self.id, {0,0}, true, {
          power = 30 * status.stat("powerMultiplier")
        })
        self.frameCooldownTimer = 0.4
      end
      self.chargeFire = false
      self.fireCooldownTimer = 0.5 + self.frameCooldownTimer
    end
  elseif self.frameCooldownTimer > 0 then
    if self.creature == "poptop" then
      mcontroller.setXVelocity(mcontroller.facingDirection() * 25)
      if self.frameCooldownTimer > 0.1 then 
        mcontroller.setYVelocity(3) 
      end
    elseif self.creature == "adultpoptop" then
      mcontroller.setXVelocity(mcontroller.facingDirection() * 10)
    elseif self.creature == "orbide" then
      mcontroller.setVelocity({self.frameCooldownTimer <= 0.1 and 0 or mcontroller.facingDirection() * 100, self.frameCooldownTimer <= 0.1 and 0 or -200})
    end
  end
end

function calculatePassives()
  local transformedStatsCopy = copy(self.transformedStats)
  if self.invulnerable 
    or ((self.creature == "poptop" or self.creature == "adultpoptop" or self.creature == "orbide") and self.frameCooldownTimer > 0.1) 
    or ((self.creature == "poptop" or self.creature == "adultpoptop") and self.altFrameCooldownTimer > 0)
    or self.wisperExplosion then
    table.insert(transformedStatsCopy, {stat = "invulnerable", amount = 1})
  end
  table.insert(transformedStatsCopy, {stat = "grit", amount = (self.crouchTimer > 0 or self.getupTimer > 0) and 1 or self.grit})
  table.insert(transformedStatsCopy, {stat = "powerMultiplier", baseMultiplier = 1 + (self.creature and status.statusProperty("ivrpg" .. config.getParameter(self.creature .. "Scaling"), 0) or 0)/50 + (string.find(self.creature or "", "poptop") and self.bloodlust/50 or 0)})
  status.setPersistentEffects("ivrpgshapeshift", self.giant and config.getParameter("giantStats", {}) or transformedStatsCopy)

  killedEnemy()
  if self.creature == "orbide" then
    applyFear()
  end

  if self.giant then
    if not self.giantHitbox then
      self.giantHitbox = world.spawnProjectile("ivrpgmeltygiant", mcontroller.position(), self.id, {0,0}, true, {
        power = 100 * status.stat("powerMultiplier")
      })
    end
  else
    if self.giantHitbox and world.entityExists(self.giantHitbox) then
      world.callScriptedEntity(self.giantHitbox, "die")
    end
    self.giantHitbox = false
    self.giantTimer = 0
  end

end

function meltyBlood()
  self.melty = status.statPositive("ivrpgmeltyblood")
  if self.melty or self.giant then
    tech.setToolUsageSuppressed(true)
  elseif not self.active then
    tech.setToolUsageSuppressed(false)
  end
end

function killedEnemy()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 then
        if string.find(self.creature or "", "poptop") then self.bloodlust = self.bloodlust + 3 end
        self.giantCounter = self.giantCounter + (self.giant and 0 or 1)
      end
    end
  end
end

function applyFear()
  local targetIds = world.entityQuery(mcontroller.position(), 20, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })
  for i,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "enemy" and (world.entityAggressive(id) or world.entityCanDamage(self.id, id)) then
      world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgfear", 1, self.id)
    end
  end
end