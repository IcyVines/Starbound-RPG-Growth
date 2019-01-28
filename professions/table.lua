function init()
  object.setInteractive(true)
end

function onInteraction(args)
  local requiredProfession = config.getParameter("proftype", 0)
  local proftype = world.entityCurrency(args.sourceId, "proftype")
  if proftype and proftype == requiredProfession then
    local interactData = config.getParameter("interactData")
    return { "OpenCraftingInterface", interactData }
  end
end

function update(args)
  
end