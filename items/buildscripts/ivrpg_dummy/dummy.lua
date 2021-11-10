require "/scripts/vec2.lua"
require "/scripts/util.lua"

Dummy = WeaponAbility:new()

function Dummy:init()

end

function Dummy:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
end

function Dummy:uninit()

end
