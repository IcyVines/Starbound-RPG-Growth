require "/scripts/keybinds.lua"

function init()

end

function uninit()

end

function update(dt)

  status.modifyResourcePercentage("health", 0.005*dt)
  mcontroller.controlModifiers({
      speedModifier = 0.9
  })

end
