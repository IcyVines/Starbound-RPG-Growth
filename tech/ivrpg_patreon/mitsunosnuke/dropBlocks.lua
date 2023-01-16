require "/scripts/vec2.lua"

function init()
  local radius = config.getParameter("radius", 30)
  local backgroundRadius = config.getParameter("backgroundRadius", 10)
  local tileGroup = {"None", "Block", "Platform", "Slippery"}
  local blocks = {}
  local ores = {}
  local focalPoint = mcontroller.position()
  local materials = root.assetJson("/tech/ivrpg_patreon/mitsunosnuke/materials.config")
  local mods = root.assetJson("/tech/ivrpg_patreon/mitsunosnuke/mods.config")
  for x=-radius,radius do
    for y=-radius,radius do
      if x^2 + y^2 <= radius^2 and not world.isTileProtected(vec2.add(focalPoint,{x,y})) then
        local material = world.material(vec2.add(focalPoint,{x,y}), "foreground")
        local mod = world.mod(vec2.add(focalPoint,{x,y}), "foreground")
        -- Get Block
        if materials[material] then material = materials[material] end
        if material then
          if blocks[material] then
            blocks[material] = blocks[material] + 1
          else
            blocks[material] = 1
          end
        end
        -- Get Ore
        if mod and mods[mod] then
          mod = mods[mod]
          if ores[mod] then
            ores[mod] = ores[mod] + 1
          else
            ores[mod] = 1
          end
        end
      end

      if x^2 + y^2 <= backgroundRadius^2 and not world.isTileProtected(vec2.add(focalPoint,{x,y})) then
        local material = world.material(vec2.add(focalPoint,{x,y}), "background")
        local mod = world.mod(vec2.add(focalPoint,{x,y}), "background")
        -- Get background Block
        if material then
          if materials[material] then material = materials[material] end
          if blocks[material] then
            blocks[material] = blocks[material] + 1
          else
            blocks[material] = 1
          end
        end
        -- Get background Ore
        if mod and mods[mod] then
          mod = mods[mod]
          if ores[mod] then
            ores[mod] = ores[mod] + 1
          else
            ores[mod] = 1
          end
        end
      end
    end
  end
  -- Spawn blocks
  for block,amount in pairs(blocks) do
    if (not string.find(block, "metamaterial")) then
      world.spawnItem(block, focalPoint, amount)
    end
  end
  -- Spawn ore
  for ore,amount in pairs(ores) do
    world.spawnItem(ore, focalPoint, amount)
  end
  sb.logInfo(sb.printJson(blocks))
  sb.logInfo(sb.printJson(ores))
end