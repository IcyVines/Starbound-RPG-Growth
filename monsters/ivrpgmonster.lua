require "/scripts/ivrpgMonsterNpcHook.lua"
require "/scripts/ivrpgutil.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/monsters/ivrpgaimonster.lua"
require "/monsters/rpgmonsters/ivrpguniquemonster.lua"

local ivrpgOldInit = init
local ivrpgOldUpdate = update
local ivrpgOldDamage = damage

function init()
  ivrpgOldInit()
  rpg_loadConfigs()
  rpg_loadVariables(monster.type(), monster.level())
  self.rpg_isMonster = true
  self.rpg_Actions = config.getParameter("ivrpgActions", false)
  if self.rpg_Actions then rpg_initUniqueMonster() end
  rpg_setHandlers()
  self.versionConfig = root.assetJson("/ivrpgVersion.config")
  if self.versionConfig.RPGAI_version and self.versionConfig.RPGAI_refactorVersion == self.versionConfig.refactorVersion then rpg_initAI() end
  if config.getParameter("ivrpgSpawnNpc", false) then rpg_spawnNpc(config.getParameter("ivrpgNpcParameters", {})) end
end

function rpg_secondInit()
  ivrpgOldInit()
  rpg_loadConfigs()
  rpg_loadVariables(monster.type(), monster.level())
  self.rpg_isMonster = true
  self.rpg_Actions = config.getParameter("ivrpgActions", false)
  if self.rpg_Actions then rpg_initUniqueMonster() end
  rpg_setHandlers()
  self.versionConfig = root.assetJson("/ivrpgVersion.config")
  if self.versionConfig.RPGAI_version and self.versionConfig.RPGAI_refactorVersion == self.versionConfig.refactorVersion then rpg_initAI() end
  if config.getParameter("ivrpgSpawnNpc", false) then rpg_spawnNpc(config.getParameter("ivrpgNpcParameters", {})) end
end

function update(dt)
  ivrpgOldUpdate(dt)
  rpg_updateEffects(dt)
  if self.versionConfig.RPGAI_version and self.versionConfig.RPGAI_refactorVersion == self.versionConfig.refactorVersion then rpg_updateAI(dt) end
  if self.rpg_Actions then rpg_updateUniqueMonster(dt) end
  if config.getParameter("rpgOwnerUuid") and not world.entityExists(config.getParameter("rpgOwnerUuid")) then
    self.shouldDie = true
    status.setResource("health", 0)
  end
end

function damage(args)
  if ivrpgOldDamage then ivrpgOldDamage(args) end
  rpg_updateDamageTaken(args)
  if self.rpg_Actions then rpg_damage(args.damage, args.sourceDamage, args.sourceKind, args.sourceId) end
end

function rpg_spawnNpc(parameters)

  local newParameters = {}
  newParameters.ivrpgSize = 1
  newParameters.aggressive = true
  newParameters.ivrpgActions = parameters.ivrpgActions
  newParameters.animationCustom = root.assetJson("/monsters/rpgmonsters/animation.config")
  if parameters.ivrpgActions and parameters.ivrpgActions.tank then
    newParameters.animationCustom.globalTagDefaults.armorType = parameters.ivrpgActions.tank.type or ""
  end
  newParameters.statusControllerSettings = {}
  --newParameters.statusControllerSettings.primaryScriptSources = {"/monsters/rpgmonsters/npc_primary.lua", "/scripts/vec2.lua"}

  local itemParameters = {}
  if parameters.items then
    local npcJson = root.assetJson("/npcs/"..parameters.type..".npctype")
    itemParameters = npcJson.items
    itemParameters.override[1][2][1].primary = parameters.items.primary
  end
  --sb.logInfo(sb.printJson(itemParameters))

  if type(parameters.species) == "table" then
    parameters.species = parameters.species[math.random(1, #parameters.species)]
  end

  local entityId = world.spawnNpc(mcontroller.position(), parameters.species, parameters.type, monster.level(), generateSeed(), {scriptConfig = newParameters, items = itemParameters})

  monster.setDropPool(nil)
  monster.setDeathParticleBurst(nil)
  monster.setDeathSound(nil)
  self.deathBehavior = nil
  self.shouldDie = true
  status.setPrimaryDirectives(string.format("?multiply=ffffff%02x", 0))
  status.setResource("health", 0)
  mcontroller.translate({0, -100000})
end
