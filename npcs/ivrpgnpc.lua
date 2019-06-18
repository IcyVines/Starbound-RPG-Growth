require "/scripts/ivrpgMonsterNpcHook.lua"
local npcOldInit = init
local npcOldUpdate = update
local npcOldDamage = damage

function init()
  npcOldInit()
  loadConfigs()
  loadVariables(npc.npcType(), npc.level())
  setHandlers()
end

function update(dt)
	npcOldUpdate(dt)
	updateEffects(dt)
end

function damage(args)
  npcOldDamage(args)
  sourceId = args.sourceId
  updateDamageTaken(args)
end
