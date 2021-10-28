require "/scripts/keybinds.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.oldStance =  3
  self.stance = 0
  self.id = entity.id()
  self.timer = 0
  self.active = status.statusProperty("ivrpgbattleaura", false)
  self.bloodCount = 0
  self.ironCount = 0
  self.ionicCount = 0
  self.waitTimer = 0
  self.bloodTimer = 0
  self.ironTimer = 0
  self.ionicTimer = 0
  self.waitTime = 5
  self.flashTimer = 0
  _, self.damageGivenUpdate = status.inflictedDamageSince()

  self.currentEnergy = status.resource("energy")
  Bind.create("f", switch)
end

function switch()
  if not self.active then
    animator.setAnimationState("blood_aura", "front")
    animator.setAnimationState("ionic_aura", "front2")
    animator.setAnimationState("iron_aura", "back")
  else
    spawnBlast(self.bloodCount == 1, self.ionicCount == 1, self.ironCount == 1)
    animator.setAnimationState("blood_aura", "off")
    animator.setAnimationState("ionic_aura", "off")
    animator.setAnimationState("iron_aura", "off")
    self.bloodCount = 0
    self.ionicCount = 0
    self.ironCount = 0
  end
  animator.playSound(self.active and "deactivate" or "activate")
  self.active = not self.active
end

function uninit()
  status.setStatusProperty("ivrpgbattleaura", self.active)
  status.clearPersistentEffects("ivrpgbattleaura")
  tech.setParentDirectives()
end

function update(args)
  --self.shiftHeld = not args.moves["run"]
  --status.addEphemeralEffect("ivrpgbattleaura" .. self.stance, 2)
  --status.removeEphemeralEffect("ivrpgbattleaura" .. self.oldStance)
  --nearbyAllies()
  incrementIonic()
  incrementIron(args.dt)
  incrementBlood()

  if self.bloodCount == 1 or self.ionicCount == 1 or self.ironCount == 1 then
    if self.bloodCount == 1 then
      self.bloodTimer = spawnBolt("fire", self.bloodTimer, args.dt)
    end

    if self.ironCount == 1 then
      self.ironTimer = spawnBolt("ice", self.ironTimer, args.dt)
    end

    if self.ionicCount == 1 then
      self.ionicTimer = spawnBolt("electric", self.ionicTimer, args.dt)
    end
  end

  if self.waitTimer <= 0 then
    self.bloodCount = math.max(self.bloodCount - args.dt / 120, 0)
    self.ionicCount = math.max(self.ionicCount - args.dt / 120, 0)
    self.ironCount = math.max(self.ironCount - args.dt / 120, 0)
  else
    self.waitTimer = self.waitTimer - args.dt
  end
  --[[
    Auras that reach a limit emit Elemental Damage: toggle to release them, dealing Nova Damage; multiple Auras releasing increases Damage and Radius exponentially.
  ]]
  animator.setGlobalTag("blood", string.format("?multiply=FFFFFF%02x", 55 + math.floor(self.bloodCount * 200)))
  animator.setGlobalTag("iron", string.format("?multiply=FFFFFF%02x", 55 + math.floor(self.ironCount * 200)))
  animator.setGlobalTag("ionic", string.format("?multiply=FFFFFF%02x", 55 + math.floor(self.ionicCount * 200)))

  if self.active then
    status.setPersistentEffects("ivrpgbattleaura", {
      {stat = "powerMultiplier", amount = 0.1 + self.bloodCount * 1.9},
      {stat = "protection", amount = 5 + self.ironCount * 45},
      {stat = "physicalResistance", amount = 0.01 + self.ironCount * 0.24}
    })
    mcontroller.controlModifiers({
      speedModifier = 1.1 + self.ionicCount * 0.4,
      airJumpModifier = 1.05 + self.ionicCount * 0.2
    })
  else
    status.clearPersistentEffects("ivrpgbattleaura")
  end

  animator.resetTransformationGroup("aura")
  if mcontroller.crouching() then
    animator.translateTransformationGroup("aura", {0, -0.875})
  end

  if self.ionicFlash then
    tech.setParentDirectives("?fade=DDDD00=0.1")
    self.ionicFlash = false
    self.flashTimer = 0.1
  end

  if self.bloodFlash then
    tech.setParentDirectives("?fade=FF0000=0.1")
    self.bloodFlash = false
    self.flashTimer = 0.1
  end

  if self.ironFlash then
    tech.setParentDirectives("?fade=9999FF=0.1")
    self.ironFlash = false
    self.flashTimer = 0.1
  end

  if self.flashTimer <= 0 then tech.setParentDirectives("") end
  self.flashTimer = math.max(self.flashTimer - args.dt, 0)
end

function incrementIonic()
  local energy = status.resource("energy")
  if energy < self.currentEnergy and self.active then
    self.ionicCount = math.min(1, self.ionicCount + (self.currentEnergy - energy) / 100)
    if self.ionicCount == 1 then
      self.ionicFlash = true
      self.waitTimer = self.waitTime
    end
  end
  self.currentEnergy = energy
end

function incrementIron(dt)
  if not self.active then return end
  local targets = enemyQuery(mcontroller.position(), 20, {}, entity.id(), true)
  if targets and #targets > 0 then
    self.ironCount = math.min(self.ironCount + dt / 30, 1)
    if self.ironCount == 1 then
      self.ironFlash = true
      self.waitTimer = self.waitTime
    end
  end
end

function incrementBlood()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if not self.active then return end
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > 0 and notification.healthLost > 0 then
        self.bloodCount = math.min(1, self.bloodCount + notification.healthLost / 1000)
        if self.bloodCount == 1 then
          self.bloodFlash = true
          self.waitTimer = self.waitTime
        end
      end
    end
  end
end

function spawnBolt(element, timer, dt)
  if self.active and timer <= 0 then
    local targets = enemyQuery(mcontroller.position(), 20, {}, entity.id(), true)
    local target = nil
    if targets then
      for _,id in ipairs(targets) do
        if world.entityExists(id) then
          target = id
        end
      end
    end
    if target and world.entityExists(target) then
      local distanceTo = world.distance(world.entityPosition(target), mcontroller.position())
      world.spawnProjectile("ivrpg_battlemage" .. element, mcontroller.position(), entity.id(), distanceTo, false, {power = status.stat("powerMultiplier") * 10, speed = 100})
      return 2
    end
  end
  return timer - dt
end

function spawnBlast(fire, electric, ice)
  if fire and electric and ice then
    world.spawnProjectile("fireplasmaexplosionstatus", mcontroller.position(), entity.id(), {8,0}, false, {power = status.stat("powerMultiplier") * 20})
    world.spawnProjectile("electricplasmaexplosionstatus", mcontroller.position(), entity.id(), {0,8}, false, {power = status.stat("powerMultiplier") * 20})
    world.spawnProjectile("iceplasmaexplosionstatus", mcontroller.position(), entity.id(), {-8,0}, false, {power = status.stat("powerMultiplier") * 20})
  elseif fire and ice then
    world.spawnProjectile("fireplasmaexplosionstatus", mcontroller.position(), entity.id(), {4,0}, false, {power = status.stat("powerMultiplier") * 15})
    world.spawnProjectile("iceplasmaexplosionstatus", mcontroller.position(), entity.id(), {-4,0}, false, {power = status.stat("powerMultiplier") * 15})
  elseif fire and electric then
    world.spawnProjectile("fireplasmaexplosionstatus", mcontroller.position(), entity.id(), {4,0}, false, {power = status.stat("powerMultiplier") * 15})
    world.spawnProjectile("electricplasmaexplosionstatus", mcontroller.position(), entity.id(), {-4,0}, false, {power = status.stat("powerMultiplier") * 15})
  elseif electric and ice then
    world.spawnProjectile("electricplasmaexplosionstatus", mcontroller.position(), entity.id(), {-4,0}, false, {power = status.stat("powerMultiplier") * 15})
    world.spawnProjectile("iceplasmaexplosionstatus", mcontroller.position(), entity.id(), {4,0}, false, {power = status.stat("powerMultiplier") * 15})
  elseif fire then
    world.spawnProjectile("fireplasmaexplosionstatus", mcontroller.position(), entity.id(), {0,0}, false, {power = status.stat("powerMultiplier") * 12})
  elseif electric then
    world.spawnProjectile("electricplasmaexplosionstatus", mcontroller.position(), entity.id(), {0,0}, false, {power = status.stat("powerMultiplier") * 12})
  elseif ice then
    world.spawnProjectile("iceplasmaexplosionstatus", mcontroller.position(), entity.id(), {0,0}, false, {power = status.stat("powerMultiplier") * 12})
  end
end

--[[function nearbyAllies()
  local targetIds = friendlyQuery(mcontroller.position(), 30, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  }, self.id)

  for i,id in ipairs(targetIds) do
    --world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgbattleaura" .. self.stance, 2, self.id)
    --world.sendEntityMessage(id, "removeEphemeralEffect", "ivrpgbattleaura" .. self.oldStance)
  end
end]]