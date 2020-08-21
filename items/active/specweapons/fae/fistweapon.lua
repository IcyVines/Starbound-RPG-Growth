require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"

function rpg_triggerFinisher(aimAngle)
  self.weapon.aimAngle = aimAngle
  self.comboFinisher:startAttack()
  finishFistCombo()
  return true
end