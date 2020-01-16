require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
  Bind.create("f", fix)
end

function fix()
  status.addEphemeralEffect("ivrpgfix")
end

function update(args)
  
end