function init()
  if player.currency("statpoint") == 250 then return end

end

function activate(fireMode, shiftHeld)
  player.addCurrency("statpoint", 1)
  item.consume(1)
end

function uninit()
end
