function init()

end

function activate(fireMode, shiftHeld)
  activeItem.interact(config.getParameter("interactAction"), config.getParameter("interactData"));
end

function uninit()

end
