function init()
  message.setHandler("holdingSkillBook", function() return true end)
end

function activate(fireMode, shiftHeld)
  if player.currency("skillbookopen") ~= 1 then
    activeItem.interact(config.getParameter("interactAction"), config.getParameter("interactData"));
    if player.currency("skillbookopen") == 2 then
    	player.consumeCurrency("skillbookopen", 1)
    end
  end
end

function uninit()

end
