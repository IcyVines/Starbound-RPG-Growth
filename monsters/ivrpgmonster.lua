require "/scripts/ivrpgMonsterNpcHook.lua"
require "/scripts/ivrpgutil.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/monsters/ivrpgaimonster.lua"

local monsterOldInit = init
local monsterOldUpdate = update

function init()
  monsterOldInit()
  loadConfigs()
  loadVariables(monster.type(), monster.level())
  setHandlers()
  initAI()
end

function update(dt)
	monsterOldUpdate(dt)
	updateEffects(dt)
	updateAI(dt)
end

function damage(args)
  sourceId = args.sourceId
  updateDamageTaken(args)
end