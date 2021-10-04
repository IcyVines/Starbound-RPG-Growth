require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.droneJson = root.assetJson("/monsters/rpgmonsters/mechanist/turret/turret.monstertype")
  self.turretJson = root.assetJson("/monsters/rpgmonsters/mechanist/drone/drone.monstertype")
  self.cooldown = config.getParameter("cooldown", 10)
  self.droneCooldownTimer = 0
  self.turretCooldownTimer = 0
  self.rechargeTimer = 0
  Bind.create("f", placeTurret)
end

function placeTurret()

  local intelligence = status.statusProperty("ivrpgintelligence", 1)
  local dexterity = status.statusProperty("ivrpgdexterity", 1)
  if status.statPositive("activeMovementAbilities") then return end

  local params = {}
  params.level = util.clamp((intelligence + dexterity) / 15, 1, 6)
  params.damageTeamType = "friendly"
  params.aggressive = true
  params.ownerUuid = entity.uniqueId()

  if mcontroller.crouching() and self.turretCooldownTimer == 0 then
    params.statusSettings = self.turretJson.baseParameters.statusSettings
    params.statusSettings.stats.maxHealth.baseValue = status.stat("maxHealth") / 2
    params.statusSettings.stats.protection.baseValue = status.stat("protection")
    params.statusSettings.stats.powerMultiplier.baseValue = (intelligence + dexterity) / 75
    world.spawnMonster("ivrpgmechanistturret", mcontroller.position(), params)
    self.turretCooldownTimer = self.cooldown
  elseif not mcontroller.crouching() and self.droneCooldownTimer == 0 then
    params.statusSettings = self.droneJson.baseParameters.statusSettings
    params.statusSettings.stats.maxHealth.baseValue = status.stat("maxHealth") / 4
    params.statusSettings.stats.protection.baseValue = status.stat("protection") / 2
    params.statusSettings.stats.powerMultiplier.baseValue = (intelligence + dexterity) / 75
    world.spawnMonster("ivrpgmechanistdrone", mcontroller.position(), params)
    self.droneCooldownTimer = self.cooldown
  end
end

function reset()
  tech.setParentDirectives()
end

function uninit()
  reset()
end

function update(args)
  if self.droneCooldownTimer > 0 then
    self.droneCooldownTimer = math.max(self.droneCooldownTimer - args.dt, 0)
    if self.droneCooldownTimer == 0 then
      animator.playSound("recharge")
      self.rechargeTimer = 0.1
      tech.setParentDirectives("?fade=aa5522=0.25")
    end
  end

  if self.turretCooldownTimer > 0 then
    self.turretCooldownTimer = math.max(self.turretCooldownTimer - args.dt, 0)
    if self.turretCooldownTimer == 0 then
      animator.playSound("recharge")
      self.rechargeTimer = 0.1
      tech.setParentDirectives("?fade=aa5522=0.25")
    end
  end

  if self.rechargeTimer > 0 then
    self.rechargeTimer = math.max(self.rechargeTimer - args.dt, 0)
    if self.rechargeTimer == 0 then
      tech.setParentDirectives()
    end
  end
end
