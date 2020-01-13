require "/scripts/util.lua"

function init()
	storage.item = storage.item or false
end

function craftingRecipe(items)
	if #items ~= 1 then return end
	local item = items[1]
	--sb.logInfo(sb.printJson(items,1))
  
	if not item then return end
	
	if not item.parameters or not item.parameters.currentAugment then
		return
	elseif item.parameters.currentAugment and item.parameters.currentAugment.itemName then

		storage.item = copy(item)
		jremove(storage.item.parameters,"currentAugment")
		storage.item.parameters.tooltipKind = "armor"

		augment = {
			name = item.parameters.currentAugment.itemName,
			count = 1,
			parameters = {}
		}
		
		animator.setAnimationState("healState","on")
		
		return {
			input = items,
			output = augment,
			duration = 1.0
		}
		
	else
		return
	end	
end

function update(dt)
	local powerOn = false
	local inventory = world.containerItems(entity.id())
  
  
  for _,item in pairs(inventory) do
    if item.parameters.currentAugment then
      powerOn = true
      break
    end
  end
  
  if storage.item and not inventory[1] and inventory[2] then
		world.containerAddItems(entity.id(),storage.item)
		--sb.logInfo(sb.printJson(storage.item,1))
		storage.item = false
  end

  if powerOn then
    animator.setAnimationState("powerState", "on")
  else
    animator.setAnimationState("powerState", "off")
  end
end
