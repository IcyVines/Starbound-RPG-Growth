require "/scripts/ivrpgMonsterNpcHook.lua"

local ivrpgOldInit = init
local ivrpgOldUpdate = update
local ivrpgOldDamage = damage

function init()
  ivrpgOldInit()
  loadConfigs()
  loadVariables(npc.npcType(), npc.level())
  setHandlers()
end

function update(dt)
	ivrpgOldUpdate(dt)
	updateEffects(dt)
end

function damage(args)
  ivrpgOldDamage(args)
  sourceId = args.sourceId
  updateDamageTaken(args)
end
