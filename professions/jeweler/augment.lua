require "/scripts/augments/item.lua"

function apply(input)
  local augmentConfig = config.getParameter("augment")
  local output = Item.new(input)
  if augmentConfig then
    if output:instanceValue("category", "") == augmentConfig.type then

      local currentAugment = output:instanceValue("currentAugment")
      if currentAugment then
        if currentAugment.name == augmentConfig.name then
          return nil
        end
      end

      augmentConfig.itemName = config.getParameter("itemName")
      output:setInstanceValue("tooltipKind", "ivrpgarmoraugment")
      output:setInstanceValue("currentAugment", augmentConfig)
      return output:descriptor(), 1
    end
  end
end