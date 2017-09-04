function init()
end

function activate(fireMode, shiftHeld)
  if item.name() == "ivrpgscrollresetaffinity" then
    consumeAllCurrency("affinitytype")
	item.consume(1)
  elseif item.name() == "ivrpgscrollresetclass" then
    local points = 0
    points = consumeAllCurrency("agilitypoint")
          + consumeAllCurrency("dexteritypoint")
          + consumeAllCurrency("endurancepoint")
          + consumeAllCurrency("intelligencepoint")
          + consumeAllCurrency("strengthpoint")
          + consumeAllCurrency("vigorpoint")
          + consumeAllCurrency("vitalitypoint")
          - 20
    player.addCurrency("statpoint", points)
    consumeAllCurrency("classtype")
	item.consume(1)
  end
end

function consumeAllCurrency(name)
  local amount = player.currency(name)
  player.consumeCurrency(name, amount)
  return amount
end

function uninit()
end
