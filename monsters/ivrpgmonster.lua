require "/scripts/ivrpgMonsterNpcHook.lua"
local monsterOldInit = init
local monsterOldUpdate = update

function init()
  monsterOldInit()
  loadConfigs()
  loadVariables(monster.type(), monster.level())
  self.isMonster = true
  setHandlers()
end

function update(dt)
	monsterOldUpdate(dt)
	updateEffects(dt)
end

function damage(args)
  sourceId = args.sourceId
  updateDamageTaken(args)
end