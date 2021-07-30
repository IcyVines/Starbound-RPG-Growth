local monsterOldInit = init
local monsterOldUpdate = update

function init()
  monsterOldInit()
  status.addEphemeralEffect("ivrpgbonemonster", 10, config.getParameter("ownerId", nil))
end

function update(dt)
  monsterOldUpdate(dt)
end
