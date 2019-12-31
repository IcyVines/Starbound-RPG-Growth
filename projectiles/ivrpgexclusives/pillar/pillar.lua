require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  local rotation = config.getParameter("rotation", 0)
  mcontroller.setRotation(rotation * math.pi / 180)
end

function update(dt)
end