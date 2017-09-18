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
    self.class = player.currency("classtype")
    removeTechs()
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

function removeTechs()
  if self.class == 3 then
    player.makeTechUnavailable("ninjaassassinate")
    player.makeTechUnavailable("ninjaflashjump")
    player.makeTechUnavailable("ninjawallcling")
    player.makeTechUnavailable("ninjavanishsphere")
  elseif self.class == 2 then
    player.makeTechUnavailable("wizardmagicshield")
    player.makeTechUnavailable("wizardgravitysphere")
    player.makeTechUnavailable("wizardtranslocate")
    player.makeTechUnavailable("wizardhover")
  elseif self.class == 1 then
    player.makeTechUnavailable("knightslam")
    player.makeTechUnavailable("knightbash")
    player.makeTechUnavailable("knightcharge!")
    player.makeTechUnavailable("knightarmorsphere")
  elseif self.class == 5 then
    player.makeTechUnavailable("roguetoxicaura")
    player.makeTechUnavailable("roguecloudjump")
    player.makeTechUnavailable("roguetoxiccapsule")
    player.makeTechUnavailable("roguepoisondash")
  elseif self.class == 4 then
    player.makeTechUnavailable("soldiermissilestrike")
    player.makeTechUnavailable("soldierenergypack")
    player.makeTechUnavailable("soldiermarksman")
    player.makeTechUnavailable("soldiermre")
  elseif self.class == 6 then
    player.makeTechUnavailable("explorerenhancedjump")
    player.makeTechUnavailable("explorerenhancedmovement")
    player.makeTechUnavailable("explorerdrill")
    player.makeTechUnavailable("explorerglide")
  end
end