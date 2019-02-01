function init()
  if player.currency("statpoint") == 322 then return end

end

function activate(fireMode, shiftHeld)
  player.addCurrency("statpoint", 1)
  status.setStatusProperty("ivrpgextrastatpoints", status.statusProperty("ivrpgextrastatpoints", 0) + 1)
  item.consume(1)
end

function uninit()
end
