require "/scripts/util.lua"
require "/interface/games/util.lua"
require "/scripts/vec2.lua"
require "/interface/games/fossilgame/generator.lua"
require "/interface/games/fossilgame/tools.lua"
require "/interface/games/fossilgame/tileset.lua"
require "/interface/games/fossilgame/ui.lua"

local oldWinState = winState

function winState()
  local extraPool = root.createTreasure("experienceorbfossilpool", world.threatLevel())
  for _,reward in ipairs(extraPool) do
    world.sendEntityMessage(pane.sourceEntity(), "addDrop", reward)
  end
  oldWinState()
end