require "/scripts/vec2.lua"

function init()
  local radius = config.getParameter("radius", 30)
  local backgroundRadius = config.getParameter("backgroundRadius", 10)
  local tileGroup = {"None", "Block", "Platform", "Slippery"}
  local blocks = {}
  local focalPoint = mcontroller.position()
  local materials = root.assetJson("/tech/ivrpg_patreon/mitsunosnuke/materials.config")
  for x=-radius,radius do
    for y=-radius,radius do
      if x^2 + y^2 <= radius^2 then
        local material = world.material(vec2.add(focalPoint,{x,y}), "foreground")
        if materials[material] then material = materials[material] end
        if material then
          if blocks[material] then
            blocks[material] = blocks[material] + 1
          else
            blocks[material] = 1
          end
        end
      end

      if x^2 + y^2 <= backgroundRadius^2 then
        local material = world.material(vec2.add(focalPoint,{x,y}), "background")
        if material then
          if materials[material] then material = materials[material] end
          if blocks[material] then
            blocks[material] = blocks[material] + 1
          else
            blocks[material] = 1
          end
        end
      end
    end
  end
  for block,amount in pairs(blocks) do
    world.spawnItem(block, focalPoint, amount)
  end
  --[[for x=-self.radius,self.radius do
    local y = math.sqrt(self.radius^2 - x^2)
    local startPoint = vec2.add(focalPoint, {x, -y})
    local endPoint = vec2.add(focalPoint, {x, y})
    local tiles = world.collisionBlocksAlongLine(startPoint, endPoint, self.tileGroup, self.radius * 2)
    for _,tile in ipairs(tiles) do
      local material = world.material(tile, "foreground")
      if not material then material = "nothing" end
      if material then
        if blocks[material] then
          blocks[material] = blocks[material] + 1
        else
          blocks[material] = 1
        end
      end
    end
  end]]
  sb.logInfo(sb.printJson(blocks))
end