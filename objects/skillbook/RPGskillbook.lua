function init()
  message.setHandler("holdingSkillBook", function() return true end)
end

function activate(fireMode, shiftHeld)
	if player.currency("skillbookopen") ~= 1 then
		if player.currency("skillbookopen") == 2 then
			player.consumeCurrency("skillbookopen", 1)
		else
			player.addCurrency("skillbookopen", 1)
		end
		activeItem.interact(config.getParameter("interactAction"), config.getParameter("interactData"));
	end
end

function uninit()

end