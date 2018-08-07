local monsterOldInit = init
local monsterOldUpdate = update

function init()
  monsterOldInit()
  status.addEphemeralEffect("ivrpgbonemonster", 10)
end

function update(dt)
	monsterOldUpdate(dt)
end
