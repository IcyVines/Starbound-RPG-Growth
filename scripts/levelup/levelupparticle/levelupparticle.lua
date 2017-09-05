require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  mcontroller.applyParameters(config.getParameter("movementSettings", {}))
end

function update(dt)

end
