function init()
end

function activate(fireMode, shiftHeld)
  if item.name() == "ivrpgscrollresetaffinity" and player.currency("affinitytype") ~= 0 then
    consumeAllCurrency("affinitytype")
	   item.consume(1)
  elseif item.name() == "ivrpgscrollresetclass" and player.currency("classtype") ~= 0 then
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
    self.statType = {"strength", "agility", "vitality", "vigor", "intelligence", "endurance", "dexterity"}
    for i = 1,7 do
      player.addCurrency(self.statType[i].."point", 1)
    end
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
